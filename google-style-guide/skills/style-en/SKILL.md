---
name: style-en
description: Check or fix English docs against the Google developer documentation style guide. For Japanese docs use style-ja.
disable-model-invocation: true
compatibility: WebFetch only as fallback; references/ is shared with style-ja - keep filenames stable
---

# Google developer documentation style (English)

The rules below are the frequent core; `references/` holds the detailed specs. Cite rules by slug when asked why; the origin page is `https://developers.google.com/style/<slug>` (exceptions: index.md).

Premises, from the guide itself:

- Priority order: 1. project-specific style → 2. this guide → 3. third-party references (Merriam-Webster, Chicago, Microsoft style guides).
- Guidelines, not rules: depart when it serves readers; stay consistent within the document.
- **[Android]**/**[Cloud]**/**[Workspace]** rules apply only to that product's docs; if the product context is unclear, confirm before applying.

## Core rules

### Voice and tone

- Be conversational and friendly without being frivolous; no slang, buzzwords, pop-culture references, or internet abbreviations (tl;dr).
- Address the reader as *you* (imperative for instructions); *user* only for the end user of the reader's own software.
- Use active voice; make the actor the subject (3 sanctioned passive cases → language.md).
- Use present tense; *will* only for actions genuinely later (async). Don't pre-announce future features or releases.
- Don't use *please* in instructions, *simply/easy/just/quickly* in procedures, or placeholder phrases (*please note*, *at this time*). Avoid exclamation points.
- Don't attribute human qualities to software ("the command specifies", not "tells").
- State the condition before the instruction ("To delete the document, click **Delete**").
- No unverifiable performance/cost claims, superlatives, or absolute security claims ("helps with security", not "is secure").
- Timeless docs: avoid *now, currently, soon, latest, new* (exceptions: blogs, release notes → writing-principles.md).
- Accessibility: no directional language (*above/below* → *preceding/following*); refer to UI elements by label; never color/size/position as the only cue.
- Inclusive: no gendered, ableist, or violent language; use singular *they*; avoid figurative language and idioms.
- Global audience: simple words (*use*, not *utilize*), short SVO sentences, consistent terminology everywhere.

### Language and grammar

- Sentence case for titles, headings, list items, and table text; no ending period in headings.
- Keep articles (*a*, *an*, *the*), even in headings. Common contractions (you're, isn't) are encouraged.
- Don't use *i.e.* / *e.g.* — write *that is* / *for example*. Spell out abbreviations on first use, abbreviation in parentheses, both italicized (→ language.md).
- Regular plurals: *APIs* not *API's*; class names stay singular; no plural/possessive of trademarks or code items.
- *That* introduces restrictive clauses (no comma); *which* nonrestrictive (with comma). Keep optional *that*.
- Clear antecedents: follow demonstrative pronouns with a noun ("this value").
- Method reference descriptions use third-person verbs ("Creates a new task"), not imperatives.

### Punctuation

- Serial (Oxford) comma. Em dash without spaces for breaks; never en dashes. One space between sentences.
- Avoid semicolons, slashes (*and/or*, slash dates), ellipses, and parentheses around important information.
- Straight quotation marks only; periods inside quotes except after literal strings/keywords.
- Hyphenate compound modifiers before nouns; don't hyphenate -ly adverbs or most prefixes (exception classes → punctuation.md).

### Formatting and structure

- Numbered lists for sequences, bulleted otherwise, description lists for term–description pairs; parallel structure across items.
- Introduce lists, tables, procedures, and code with a complete sentence ending in a colon, never a partial sentence (→ structure.md).
- Headings: task headings use a bare infinitive ("Create an instance"), conceptual are noun phrases; never start with -ing; no links, numbers, or bare code.
- Procedures: start each step with an imperative verb; one action per step; state the location before the action; combine menu selections ("**File > New > Document**"); optional steps start "Optional:".
- Bold (`**`) only for UI element names. Italics (`_`) for new terms and words-as-words. Code font for code items, filenames, commands (item list → code-in-text.md). Never bold or underline for emphasis.
- Placeholders: UPPER_SNAKE_CASE, explained on first use (→ commands-placeholders.md).
- Use notices (Note/Caution/Warning) sparingly, never nested (type criteria → notices-images.md).
- Spell out zero through nine, numerals from 10 (exceptions → numbers-dates-units.md). Unambiguous dates: "January 19, 2017", numeric only as YYYY-MM-DD.
- Links: descriptive link text, never *click here* or a bare URL; introduce with "For more information, see ..." (→ linking.md).
- Every image needs alt text; never present information only in an image; never screenshot text or code.
- Examples: only reserved example domains, names, IPs, and phone numbers (→ example-values.md); never real PII; project names never *foo/bar/baz*.

### Word choice

Check word-list-entries.md first — it keeps the severity tiers ("Don't use" = hard ban; "Avoid" = soft) and scope labels. Frequent traps:

- Version ranges: *later/earlier* — **[Android]** inverts this to *higher/lower*.
- Noun closed / verb open: *login*/*log in*, *setup*/*set up*, *startup*/*start up*, *timeout*/*time out*.
- UI verbs: *click* (mouse, never "click on"), *tap* (touch), *press* (keys), *enter* (text), *select/clear* (checkboxes, never check/uncheck), *hold the pointer over* (not hover).
- *lets you*, not "allows you to" / "enables you to". *because*, not causal *since*. *although*, not contrastive *while*.
- Memorize, don't derive: *filename* but *file system*; *checkbox* but *text box*; *sub-command* but *subnet*.

Words with no entry: fetch the origin word-list page (slug `word-list`; anchors aren't guessable); if you can't fetch, defer the judgment — never extrapolate from word-list-principles.md.

## Workflow

- **Fixing**: scan against the core rules; before editing, read the reference files for the element types present. Apply product-scoped rules only to that product's docs; if unclear, ask.
- **Writing**: apply the core rules from the start; read the reference files for the elements the document will contain.
- **Reviewing** (no edits): per finding give the quoted text, rule + slug, a rewrite, and the severity tier.
- **Explaining**: name the rule and its slug (e.g. "sentence-case headings — capitalization").
- Japanese body text → defer to style-ja (English UI labels, code, and commands inside it still follow these rules).

## Reference map

All files are in `references/`:

| Topic / element type | Read |
|---|---|
| Voice, abbreviations, capitalization, product names, plurals | language.md |
| must/can/might, timeless, inclusive, jargon, translation | writing-principles.md |
| Commas, periods, quotes, hyphens, introducing examples | punctuation.md |
| Lists, procedures, tables, headings | structure.md |
| Numbers, dates, times, units | numbers-dates-units.md |
| Notices, images, alt text, captions | notices-images.md |
| Links and cross-references | linking.md |
| Code font, API reference wording, code samples | code-in-text.md |
| Commands, arguments, placeholders | commands-placeholders.md |
| UI elements, keyboard keys, verbs | ui-elements.md |
| Example values (domains, IPs, phones), filenames | example-values.md |
| Specific words | word-list-entries.md |
| Anything else | index.md → fetch origin by slug (can't fetch → defer the judgment) |

## Examples

- "Fix this README to follow the Google style guide"
- "Why did you change 'allows you to' here?"
