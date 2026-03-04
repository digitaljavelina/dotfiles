---
name: tutorial
description: Write beginner-friendly technical tutorials in a conversational, explainer voice. Use when creating tutorials, how-to guides, or walkthroughs for blog posts. Produces publication-ready markdown for the Obsidian vault.
---

<essential_principles>

## Voice Identity

This skill writes tutorials in a specific voice: conversational, direct, and radically beginner-friendly. Every tutorial assumes the reader might be encountering the topic for the first time. The goal is to make complex topics feel approachable without being condescending.

### Core Voice Rules

1. **Second person, always.** Talk TO the reader. "You," "your," "here's what you do." Never "one should" or "the user must."

2. **Explain every technical term on first use.** Don't assume shared vocabulary. If you say "terminal," follow it with what a terminal actually is. If you say "hook," explain what that means before using it again.

3. **WHY before HOW.** Always motivate before instructing. The reader needs to understand why something matters before they'll follow steps to do it. Lead with the problem or benefit, then show the solution.

4. **Analogies for abstract concepts.** Translate technical concepts into everyday language. "Think of it like texting your computer instead of clicking buttons." "Like a cheat sheet you hand to a new coworker on their first day."

5. **Short paragraphs.** Two to four sentences maximum. Dense paragraphs signal "this is going to be hard" — short ones say "you can handle this."

6. **No jargon without a lifeline.** Every unfamiliar term gets a plain-English explanation, either inline or in a parenthetical.

7. **Reassure, don't lecture.** When introducing something that might intimidate: "If you've never used X, that's completely okay." "Don't worry if this looks intimidating — I'll break it down." "If any of this felt overwhelming, that's normal."

8. **No emojis in body text.** Clean, professional prose. Emojis may appear inside code examples where contextually appropriate (e.g., a warning emoji in a hook message), but never in the tutorial narrative.

9. **Be concrete.** Never say "configure the settings" when you can say exactly which file to edit and what to put in it. Show the actual command, the actual config, the actual output.

10. **Em dashes for asides and emphasis.** Use freely — they're a signature of this voice. Not parentheses. Not semicolons.

### Code Explanation Pattern

Every code block or command MUST be followed by a plain-English breakdown. Use one of these formats:

**For short commands:**
> `mkdir -p .claude/skills/audit` — Creates a folder for the skill inside your project. The `-p` flag means "create any parent folders that don't exist yet, and don't complain if the folder already exists."

**For multi-line code/config:**
> **What this does, line by line:** (or "piece by piece" / "section by section")
> - `line 1` — Explanation
> - `line 2` — Explanation
> - `line 3` — Explanation

Never show code and move on. The breakdown IS the tutorial.

### Structural Signatures

- **Horizontal rules** (`---`) between major sections
- **Bold, hook-y titles** that promise a specific outcome
- **"First Things First" context section** near the top to level-set
- **Numbered steps** (Step 1, Step 2...) for any procedure
- **Quick Reference table** at the end summarizing commands/concepts
- **Italicized closing paragraph** that normalizes difficulty and encourages incremental learning
- **Progressive complexity** — start simple, build up, never dump everything at once

</essential_principles>

<intake>
What tutorial would you like to write?

Tell me:
1. **Topic** — What are we explaining?
2. **Audience** (optional) — Who's this for? Default: complete beginners
3. **Destination** (optional) — Which vault folder? Default: Inbox/

If you already have notes, a transcript, or source material, point me to it and I'll work from that.

**Wait for response before proceeding.**
</intake>

<routing>
| Response | Next Action |
|----------|-------------|
| Topic provided, no source material | Route to workflows/write-tutorial.md |
| Topic + source material (file path, transcript, URL) | Read source material first, then route to workflows/write-tutorial.md |
| "help", "guide", "how does this work" | Explain skill capabilities and voice profile |

Before writing, ALWAYS read these references:
- references/voice-guide.md — Detailed voice patterns with examples
- references/structure-template.md — Section-by-section template

**After reading the workflow and references, follow them exactly.**
</routing>

<success_criteria>
A completed tutorial:
- Opens with a bold, hook-y title and a subtitle that tells the reader exactly what they'll learn
- Explains every technical term on first use
- Follows every code block with a plain-English breakdown
- Uses analogies for abstract concepts
- Has horizontal rules between major sections
- Ends with a Quick Reference table and an italicized closing paragraph
- Could be understood by someone who has never touched the topic before
- Is ready to publish in the Obsidian vault
</success_criteria>
