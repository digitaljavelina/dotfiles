#!/usr/bin/env python3
"""Firecrawl backend router: cloud-first, self-hosted fallback.

Resolves which Firecrawl API endpoint to use and prints it on stdout.

Cloud credits reset monthly, so this is a reversible switch, not a one-way
door. The cached decision expires (CACHE_TTL) and the router re-checks, which
is what lets it drift back to cloud on its own after a billing-cycle refill.

Checking the balance is free and costs no credits, so the cache exists to avoid
an HTTP round-trip on every scrape, not to save money.

Stowed from ~/.dotfiles/bin/, driven by the ~/bin/firecrawl shim.

Usage:
    fc_router.py <command>              # print the API URL to use (cached)
    fc_router.py <command> --explain    # print the decision and why, to stderr
    fc_router.py <command> --refresh    # ignore the cache, re-probe backends
"""

from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

CLOUD_URL = "https://api.firecrawl.dev"
SELF_HOSTED_URL = os.environ.get(
    "FIRECRAWL_SELF_HOSTED_URL", "http://100.93.17.61:3002"
)

CREDENTIALS = Path.home() / "Library/Application Support/firecrawl-cli/credentials.json"
CACHE = Path.home() / ".cache/firecrawl-router/state.json"
CACHE_TTL = 900  # seconds; upper bound on how long we stay wrong after a refill

PROBE_TIMEOUT = 6


def load_api_key() -> str | None:
    """Read the cloud API key the firecrawl CLI already stores."""
    try:
        return json.loads(CREDENTIALS.read_text()).get("apiKey") or None
    except (OSError, json.JSONDecodeError):
        return None


def fetch_credits() -> int | None:
    """Remaining cloud credits, or None if cloud is unreachable or unauthenticated.

    None means "unknown", which is a different thing from zero. A caller must
    not read None as "out of credits".
    """
    key = load_api_key()
    if not key:
        return None
    req = urllib.request.Request(
        f"{CLOUD_URL}/v2/team/credit-usage",
        headers={"Authorization": f"Bearer {key}"},
    )
    try:
        with urllib.request.urlopen(req, timeout=PROBE_TIMEOUT) as resp:
            payload = json.loads(resp.read())
        return int(payload["data"]["remainingCredits"])
    except (urllib.error.URLError, KeyError, ValueError, TimeoutError, OSError):
        return None


def self_hosted_healthy() -> bool:
    """Whether the self-hosted instance answers. It has no credit endpoint."""
    try:
        with urllib.request.urlopen(SELF_HOSTED_URL, timeout=PROBE_TIMEOUT) as resp:
            return resp.status == 200
    except (urllib.error.URLError, TimeoutError, OSError):
        return False


# ---------------------------------------------------------------------------
# ROUTING POLICY
# ---------------------------------------------------------------------------

# Probed against the self-hosted instance on 2026-07-16: `agent` fails to start,
# `browser` reports BROWSER_SERVICE_URL missing, and `credit-usage` errors since
# a local deployment tracks no balance. `interact` drives a browser session, so
# it inherits that limit. These cannot be served locally at all, so credit state
# does not enter into routing them.
CLOUD_ONLY_COMMANDS = frozenset({"agent", "browser", "interact", "credit-usage"})

# Credits held back from routine scraping. Its real job is protecting the
# cloud-only commands: a runaway crawl (1 credit per page) would otherwise drain
# the balance and take agent/browser down with it, and those have no fallback.
# Sits well above observed burn (13-23 credits/month), so it never binds during
# normal work. Set to 0 to spend every last credit before failing over.
CREDIT_RESERVE = 50


def choose_backend(
    command: str, credits: int | None, self_hosted_up: bool
) -> tuple[str, str]:
    """Decide which backend to route to.

    Args:
        command: The firecrawl subcommand being run (e.g. "scrape", "agent").
            Commands in CLOUD_ONLY_COMMANDS have no self-hosted implementation.
        credits: Remaining cloud credits, or None if the cloud balance could
            not be read (network down, bad key, API error). None is *unknown*,
            not zero.
        self_hosted_up: Whether the self-hosted instance responded to a health
            probe.

    Returns:
        (api_url, reason) - api_url is CLOUD_URL or SELF_HOSTED_URL; reason is a
        short human-readable explanation shown by --explain and logged to cache.
    """
    if command in CLOUD_ONLY_COMMANDS:
        return CLOUD_URL, f"{command} has no self-hosted implementation"

    if credits is None:
        # The balance lookup failed, which usually means cloud is unreachable.
        # Prefer the backend we know is answering.
        if self_hosted_up:
            return SELF_HOSTED_URL, "cloud balance unreadable, self-hosted is up"
        return CLOUD_URL, "cloud balance unreadable and self-hosted is down"

    if credits > CREDIT_RESERVE:
        return CLOUD_URL, f"{credits:,} credits available, reserve is {CREDIT_RESERVE}"

    if self_hosted_up:
        return SELF_HOSTED_URL, f"cloud at reserve floor ({credits} <= {CREDIT_RESERVE})"

    # Below the reserve with no self-hosted fallback. Cloud anyway: the reserve
    # is our own floor, not the provider's, so residual credits still work. A
    # real out-of-credits error is also more actionable than a connect timeout.
    return CLOUD_URL, f"below reserve ({credits}) but self-hosted is down"


# ---------------------------------------------------------------------------


def read_cache() -> dict | None:
    """Cached probe results, or None if absent or stale.

    Only the probe results are cached, never the routing decision itself. The
    decision depends on the command, which changes call to call.
    """
    try:
        state = json.loads(CACHE.read_text())
    except (OSError, json.JSONDecodeError):
        return None
    if time.time() - state.get("checked_at", 0) > CACHE_TTL:
        return None
    return state


def write_cache(state: dict) -> None:
    try:
        CACHE.parent.mkdir(parents=True, exist_ok=True)
        CACHE.write_text(json.dumps(state))
    except OSError:
        pass  # a cache we cannot write is a slow router, not a broken one


def probe(refresh: bool = False) -> dict:
    if not refresh:
        cached = read_cache()
        if cached:
            return cached | {"cached": True}

    state = {
        "credits": fetch_credits(),
        "self_hosted_up": self_hosted_healthy(),
        "checked_at": time.time(),
    }
    write_cache(state)
    return state | {"cached": False}


def resolve(command: str, refresh: bool = False) -> dict:
    p = probe(refresh=refresh)
    url, reason = choose_backend(command, p["credits"], p["self_hosted_up"])
    return {"url": url, "reason": reason, **p}


def main() -> int:
    argv = sys.argv[1:]
    positional = [a for a in argv if not a.startswith("-")]
    command = positional[0] if positional else "scrape"
    state = resolve(command, refresh="--refresh" in argv)

    if "--explain" in argv:
        credits = state.get("credits")
        print(
            f"firecrawl {command} -> {state['url']}\n"
            f"  reason:  {state['reason']}\n"
            f"  credits: {'unknown' if credits is None else format(credits, ',')}\n"
            f"  probe:   {'cached' if state.get('cached') else 'fresh'}",
            file=sys.stderr,
        )

    print(state["url"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
