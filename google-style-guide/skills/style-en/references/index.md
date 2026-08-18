# Full page index

Complete index of the Google developer documentation style guide. Use this when SKILL.md's topic map and the topic reference files don't answer the question. Each entry: `slug` — what the page rules on → where it's covered locally. Entries marked *(origin only)* are not summarized locally: derive the origin URL from the slug (see SKILL.md) and fetch the page.

For rare pages, the one-line summary below IS the rule; read the origin page only when the summary doesn't settle the question.

## Key resources

- `word-list` — usage dictionary of ~728 terms → word-list-principles.md, word-list-entries.md (selection; uncovered words: fetch origin)
- `product-names` — title case for Google products, official capitalization, no shortening, articles before names, never a verb → language.md
- `text-formatting` — official formatting summary (bold/italics/code font/caps) → SKILL.md core; unique bits: in Markdown use `**` for bold (not `__`) and `_` for italics (not `*`); never override global font type/size/color inline

## General principles

- `accessibility` — alt text, heading hierarchy, link text, no visual-only cues, no directional language → SKILL.md core; HTML specifics (aria-label for `>` menu paths, `th`/`scope`/`headers` table markup, form labels, 4.5:1 contrast, focus alternates) *(origin only)*
- `excessive-claims` — no unverifiable performance/cost claims, no superlatives, no absolute security claims → writing-principles.md
- `future` — never pre-announce future features or products (unless approved by legal counsel) → writing-principles.md
- `translation` — write for a global audience: simple words, short SVO sentences, helper words, consistent terms, no idioms → writing-principles.md
- `inclusive-documentation` — avoid gendered/ableist/violent/socially charged language; replace & write-around patterns for established terms → writing-principles.md
- `jargon` — write around jargon, replace via word list, or define in parentheses on first use; code jargon stays in code font → writing-principles.md
- `prescriptive-documentation` — recommend one way; must/can/might/We recommend mapping; avoid ambiguous "should" → writing-principles.md
- `other-sources` — never copy text, images, or code from third parties (including Wikipedia, OSS docs, GitHub); paraphrase and link; OK only if your company owns the assets
- `timeless-documentation` — document the current version; avoid time-anchoring words (now, currently, soon, latest, new) → writing-principles.md
- `tone` — conversational and friendly, not frivolous or formal → SKILL.md core; self-editing techniques (read aloud, colleague check) *(origin only)*

## Language and grammar

- `abbreviations` — spell-out flow, forbidden abbreviations (e.g., i.e.), periods, a/an choice → language.md
- `voice` — active voice; three sanctioned passive cases → language.md
- `anthropomorphism` — don't attribute human qualities to software/hardware ("the command specifies", not "tells"; "detects", not "sees")
- `articles` — always include *a*/*an*/*the*, including in headings and titles ("Create a VM instance")
- `capitalization` — sentence case everywhere, colon rules, no all-caps/camel case outside official names and code → language.md
- `contractions` — use common two-word contractions (you're, don't) and prefer negation contractions (isn't, can't); never invented (guides're) or three-word (mightn't've) contractions
- `pluralization` — regular plurals, no 's plurals, abbreviation/unit plurals, singular class names → language.md
- `possessives` — 's rules by noun type; no possessives of trademarks or code items → language.md
- `prepositions` — ending a sentence with a preposition is fine; use exactly as many prepositions as clarity needs
- `tense` — present tense; *will* only for actions genuinely later (async); no hypothetical *would*
- `pronouns` — unambiguous antecedents; demonstrative pronoun + noun ("this value"); singular *they*; *that* = restrictive (no comma), *which* = nonrestrictive (comma)
- `person` — address the reader as *you*; imperative for instructions; *user* only for the reader's own users; third person for what software does
- `sentence-structure` — state the condition, circumstance, or goal before the instruction ("To delete the document, click **Delete**")
- `reference-verbs` — method reference descriptions use third-person verbs ("Creates a new task"), not imperatives

## Punctuation

All ten pages → punctuation.md:
`colons` (intro text must stand alone; lowercase after), `commas` (serial comma, clause rules), `dashes` (em dash unspaced; en dash banned), `ellipses` (avoid; drop UI "..."), `hyphens` (prefixes, compounds, units — exception-dense), `parentheses` (keep unimportant and short), `periods` (URLs, quotes, exclamation-point policy), `quotation-marks` (straight only; when to use; literal-string flip), `semicolons` (avoid, three preferred cases), `slashes` (avoid; no and/or, no slash dates)

## Formatting and organization

- `dates-times` — 12-hour clock, spelled-out dates, comma rules, ISO fallback → numbers-dates-units.md
- `format-examples` — introducing examples with *such as* / *for example* / *like* → punctuation.md
- `images` — alt text spec, figure captions "Figure N.", no text-as-images → notices-images.md
- `footnotes` — avoid footnotes (accessibility, localization); use a cross-reference, note, or parenthetical; last resort: superscript number + footnote at page bottom
- `headings` — sentence case, task vs conceptual phrasing, no -ing start, hierarchy → structure.md
- `italics-terms` — italicize a new term on first defined mention and words-as-words; never bold or quotation marks for these
- `lists` — list types, intro sentences, capitalization/punctuation matrix → structure.md
- `mathematical-notation` — HTML entities for math symbols, italic variables, sup/sub → numbers-dates-units.md (brief)
- `notices` — Note/Caution/Warning/Success ladder and Note criteria → notices-images.md
- `numbers` — words vs numerals with exceptions, percentages, ranges, comma grouping → numbers-dates-units.md
- `paragraph-structure` — one idea per paragraph, key point first, left-align, no forced line breaks, 5-6 sentences as a split signal
- `phone-numbers` — reserved 800-555-01xx examples, nonbreaking hyphens, +country code → example-values.md
- `procedures` — step structure end to end → structure.md
- `tables` — list-vs-table decision, captions "Table N.", semantic markup → structure.md
- `units-of-measure` — nonbreaking space before units, ranges, per, decimal vs binary bytes → numbers-dates-units.md

## Linking

- `cross-references` — link text options, intro formulas, unexpected behavior → linking.md
- `headings-targets` — custom anchors, preserving old anchors on heading revision → linking.md

## Computer interfaces

- `api-reference-comments` — reference doc comment phrasing, verb formulas → code-in-text.md
- `code-in-text` — code-font item list, HTTP status codes, boolean nuance → code-in-text.md
- `code-samples` — indentation, 80-char wrap, omission comments → code-in-text.md
- `code-syntax` — command formatting, argument notation, prompts, output → commands-placeholders.md
- `placeholders` — UPPER_SNAKE naming, markup, "Replace the following:" templates → commands-placeholders.md
- `ui-elements` — bold UI names, element terminology, keyboard keys, prepositions, verbs → ui-elements.md

## HTML and CSS

- `semantic-tagging` — use HTML elements for their purpose: `em` only for emphasis (else `i`), `strong` only for importance (else `b`), `br` only for content line breaks, no layout tables or frames, headings never for visual styling
- `html-formatting` — spaces not tabs, 2-space indent, lowercase elements/attributes, no trailing spaces, 80-char source lines (exceptions: `meta` elements single-line; long URLs on their own line)
- `markdown` — HTML vs Markdown is preference; follow the team or template convention; HTML is more expressive (semantic tags, special characters)

## Names and naming

- `examples` — reserved example domains, names, IPs, phone numbers, addresses → example-values.md
- `filenames` — lowercase hyphenated ASCII names, extension→type-name table → example-values.md
- `trademarks` — use a trademark only as a modifier of a noun ("a Chromebook notebook computer"), never a standalone noun, verb, possessive, or plural; follow the owner's usage guidelines

## Pages excluded from this skill

- `whats-new` — change history since 2017, not style rules (useful only for tracking guide updates)
- `index` (About this guide) and `philosophy` — premises folded into SKILL.md (reference hierarchy, break-the-rules)
- `highlights` — the official summary; its content is SKILL.md's core

## URL derivation exceptions

Origin URLs normally derive from the slug (see SKILL.md). Known exceptions:

- Origin pages that exist but are NOT mirrored or summarized here: `spelling` (American spelling; follow Merriam-Webster), `fonts` (don't override font type/size/color). Fetch them directly when needed.
- Redirect slugs that appear inside origin text but are not the canonical page: `wordlist` → `word-list`, `commas-serial` → `commas` (serial-commas section), `dates` → `dates-times`, `file-names` → `filenames`, `link-text` → `cross-references`.
- Word-list anchors are not derivable from the term (`e.g.` → `#eg`); link to the `word-list` page, never guess a `#term` anchor.
