<required_reading>
Read before starting:
- references/voice-guide.md
- references/structure-template.md
</required_reading>

<objective>
Write a complete, publication-ready tutorial that matches the voice profile and structural template. The tutorial should be immediately publishable in the Obsidian vault.
</objective>

<process>

## Phase 1: Research and Understand

1. **Clarify the topic scope.** If the user provided a topic, confirm:
   - What specific outcome will the reader achieve by the end?
   - What's the ONE prerequisite the reader needs? (This becomes the "First Things First" section.)
   - What's the most surprising or useful aspect? (This becomes the deep dive hook.)

2. **Gather source material.** If the user pointed to files, transcripts, or URLs:
   - Read all source material thoroughly
   - Identify the key concepts, commands, and configurations to cover
   - Note anything that needs a beginner-friendly explanation

3. **If the topic is technical, research it.** Use web search or documentation tools to ensure accuracy. Never guess at commands, flags, or configurations.

## Phase 2: Outline

4. **Draft the section outline.** Map the topic onto the structure template:
   - Title (bold, outcome-oriented, with hook)
   - Subtitle/deck (what, why, who)
   - First Things First (the one prerequisite)
   - Core Concept (what is this, why does it matter)
   - How-To (numbered steps)
   - What to Expect (output walkthrough)
   - Deep Dives (2-4 major sub-topics)
   - Bigger Picture (how it all fits together)
   - Quick Reference table
   - Closing paragraph

5. **Present the outline to the user for approval.** Show:
   - The proposed title
   - The section list with one-line descriptions
   - Any decisions you need from the user (scope, audience, depth)

   **Wait for approval before writing.**

## Phase 3: Write

6. **Write the tutorial section by section**, following these rules for EVERY section:

   **Voice checks (apply to every paragraph):**
   - [ ] Is this second person? ("you" not "one" or "the user")
   - [ ] Are paragraphs 4 sentences or fewer?
   - [ ] Is every technical term explained on first use?
   - [ ] Does motivation come before instruction?

   **Code block checks (apply to every code example):**
   - [ ] Is the language specified for syntax highlighting?
   - [ ] Is there a line-by-line breakdown immediately after?
   - [ ] Does the breakdown explain what each piece does in plain English?
   - [ ] Are flags and symbols explained? (`-p`, `>`, `|`, `~`, `<<`, `EOF`)

   **Section checks:**
   - [ ] Does every major section start with WHY, not HOW?
   - [ ] Are there horizontal rules between major topic shifts?
   - [ ] Is there at least one analogy per new concept?
   - [ ] Is there at least one reassurance per potentially intimidating section?

7. **Write the Quick Reference table.** Include every command, file, concept, or tool mentioned in the tutorial.

8. **Write the closing paragraph.** Italicize it. Follow the pattern:
   - Acknowledge difficulty is normal
   - Point to ONE simple starting action
   - Encourage incremental learning
   - End warmly

## Phase 4: Review

9. **Self-review checklist.** Read the completed tutorial and verify:
   - [ ] Title is bold and promises a specific outcome
   - [ ] Subtitle sets expectations for content AND audience
   - [ ] Every code block has a plain-English breakdown
   - [ ] No unexplained jargon
   - [ ] Progressive complexity (simple → advanced)
   - [ ] Horizontal rules between major sections
   - [ ] Quick Reference table is complete
   - [ ] Closing paragraph is italicized and reassuring
   - [ ] No passive voice in instructions
   - [ ] No walls of text (check paragraph lengths)
   - [ ] No emojis in prose

10. **Save the tutorial.** Write to the destination folder (default: Inbox/ in the vault). Use a descriptive, hyphen-separated filename.

</process>

<output_conventions>

## File Output

- **Format:** Markdown (.md)
- **Location:** User-specified folder, or `Posts/` by default
- **Filename:** Descriptive, hyphen-separated, title-case (e.g., `Claude-Code-Insights-Command-Guide.md`)
- **No frontmatter** unless user requests it — the tutorial is pure markdown content

## Length Guidelines

- **Short tutorial** (single concept): 1,000–2,000 words
- **Standard tutorial** (feature walkthrough): 2,000–4,000 words
- **Deep dive** (comprehensive guide): 4,000–6,000 words

The insights blog post model is ~3,500 words — a solid standard tutorial length. Don't pad to reach a word count. Don't cut to stay under one. Let the topic dictate the length.

</output_conventions>

<success_criteria>
The tutorial is done when:
- A complete beginner could follow it from start to finish without getting stuck
- Every code block has an accompanying plain-English breakdown
- The structure matches the template (title → context → concept → how-to → deep dive → reference → closing)
- The voice is conversational, direct, and reassuring throughout
- It's saved to the vault and ready to publish
</success_criteria>
