# Word list: how to read it, and its principles

Read this before applying word-list entries: it defines the word list's severity vocabulary, scope labels, and the 12 recurring principles behind the entries in `word-list-entries.md`.

## How to read entries {#reading-entries}

- **Severity tiers (defined by the guide itself):**
  - **Don't use** — in all cases, prefer not to use the term. It is particularly ambiguous, offensive, or non-inclusive. If it appears in code, replace or write around it.
  - **Avoid / Use with caution** — avoid the term *when possible*; it may be ambiguous or obscure. You can use it if needed — where appropriate, define it on first use or use it only once.
  - **Form prescriptions** ("Not *file name*", "Hyphenate", "Lowercase") — pure orthography; no severity language, just the correct form.
- **Scope labels**: **Android**, **Google Cloud**, **Google Workspace** mean the directive applies only to that documentation set.
- **Default spelling**: if a word has no entry, use Merriam-Webster's first-listed spelling (e.g. *canceled*, not *cancelled*).
- **Code-literal escape hatch**: when a banned term (*master*, *slave*, the *blacklist* family) is a literal item in the code you document, use the word only in direct reference to the code item, formatted as code, make clear what it refers to, and use the neutral term thereafter.

## Boundary: entries only, no extrapolation {#boundary}

These principles exist to help you understand and remember the entries — they are NOT a license to invent judgments for words that have no entry. For any word not covered in `word-list-entries.md`, check the origin word-list page; if it has no entry there either, fall back to Merriam-Webster and the guide's general pages.

## The 12 recurring principles {#principles}

### P1. No directional language {#p1-directional}
Never locate things visually. Document positions are *earlier/preceding* and *later/following* (not *above/below/higher/lower*); UI instructions are written non-directionally (not *under*, *left-nav*, *scroll up*); version ranges are *earlier/later*.

### P2. Inclusive language {#p2-inclusive}
Terms with racial, ethnic, or cultural baggage are banned outright, including when discussing code (use the code-literal escape hatch). Examples: *blacklist/whitelist*, *blackhat*, *master/slave*, *grandfathered*, *native* (for people), *first-class citizen*, *ghetto*, *gypsy*, *tribal knowledge*.

### P3. Gender-neutral language {#p3-gender}
Singular *they* is the preferred pronoun; never *he/she* or *(s)he*. Man-compounds get neutral replacements (*person hours*, *staffed*, *on-path attacker*, *socket/plug*); groups are *everyone* or *folks*, not *guys*.

### P4. No ableist framing {#p4-ableist}
Mental-health and disability words never describe systems or code: *confidence check* not *sanity check*, *valid* not *sane*, *stop responding* not *hung*, *unavailable* not *grayed-out*. For people, use person-first phrasing (*person who is blind*).

### P5. No violent or graphic metaphors {#p5-violent}
Replace killing/war/explosion imagery with the literal operation: *stop/exit/cancel/end* (not *kill/nuke*), *affected area* (not *blast radius*), *perimeter network* (not *DMZ*), *incident-management team* (not *war room*).

### P6. Plain language over Latinisms, jargon, colloquialisms {#p6-plain}
Latin abbreviations are written out in English (*for example*, *that is*, *versus*); *via* is banned. Slang and insider jargon (*leverage*, *performant*, *spin up*, *canary*, *cold/warm/hot failover*) is replaced or defined on first use.

### P7. Precision: choose the unambiguous near-synonym {#p7-precision}
The most common rationale in the list. Words with two readings are reserved for one: *since/while/once/as* keep only their time senses (*because*, *although*, *after* for the others); *may* = policy permission, *might* = possibility, *can* = ability; *deprecated* ≠ removed.

### P8. Timeless documentation {#p8-timeless}
No words that date the page or leak roadmap: *currently*, *now*, *soon*, *eventually*, *future*, *as of this writing*, *does not yet*, *latest*, *new*, *old*. Anchor claims with version numbers or dates instead.

### P9. Voice: "you", no fake politeness, no first-person plural {#p9-voice}
Address the reader as *you* (*user* is only for the reader's own users); don't use *we* for the reader's actions; avoid *let's*; *please* only when genuinely asking a favor; *want/need*, not *desire/wish*.

### P10. One canonical verb per UI interaction {#p10-ui-verbs}
Fixed vocabulary: *click* (mouse; never *click on*), *tap* (touch), *press* (keys, mechanical buttons), *enter* (text), *select/clear* (checkboxes; never *check/uncheck/deselect* a checkbox), *drag* (not *drag and drop*), *hold the pointer over* or *point to* (not *hover*).

### P11. Orthography: closed compounds; noun/adjective closed, verb open {#p11-compounds}
The productive pattern: nouns/adjectives close up, verbs stay open — *login*/*log in*, *setup*/*set up*, *startup*, *timeout*, *sign-in*/*sign in*, *plugin* (n) / *plug-in* (adj) / *plug in* (v). Fixed spellings must be memorized, not derived: *filename* but *file system*; *checkbox* but *text box*; *sub-command* but *subnet*; *backend*, *frontend*, *hostname*, *whitespace*, *email*.

### P12. Write for a global audience {#p12-global}
Avoid US-centric references (*the holidays*, *Black Friday* → specific months, *peak scale event*) and constructions that translate badly (keep *then* in if-statements; *send email*, not *email* as a verb; *US*, not *U.S.*).

## Traps to memorize {#traps}

- **The Android inversion**: general docs use *later/earlier* for version ranges; Android docs use *higher/lower*. Also Android-only: *tap* not *touch*, *admin* not *administrator*, *touch & hold* not *long press*.
- **Cloud/Workspace**: use *field*, not *box*, for text boxes.
- **Noun-only reclaimed words**: even *allowlist*/*denylist* are banned as verbs — rewrite the action instead of writing *allowlisted*.
- **Inconsistent spellings** (P11) cannot be derived from the pattern — look them up.
