# Writing principles

Covers slugs: prescriptive-documentation, timeless-documentation, excessive-claims, future, inclusive-documentation, jargon, translation, tone.

## Prescriptive documentation (prescriptive-documentation)

Recommend a way to achieve the task instead of listing options; when a goal involves multiple approaches or products, recommend a path. State a clear, specific purpose per document; make scenarios and procedures reflect readers' most likely use cases; provide sample commands and arguments for the most common use case.

### Word choice for recommendations and requirements (prescriptive-documentation)

Generally avoid *should*: it implies recommended-but-optional and leaves readers unsure. Determine whether an action is required vs. optional, an outcome expected vs. possible, or a state actual vs. recommended, then map:

| Intent | Use |
| --- | --- |
| Action required | *must*, or a clear imperative ("Do the following before you continue.") |
| Action recommended | *We recommend...* / *Google recommends...*. Exception: *should* is OK for a generally recognized recommendation ("You should use a strong password...", "You should follow the principle of least privilege....") |
| Action optional | *can* ("You can also use approach B to solve the same problem.") |
| Outcome expected | State it plainly ("The process returns 10 items.") |
| Outcome possible | *might* or *can* ("The process can take about 30 minutes.") |
| Actual state | Never "The value should be true." Clarify: "You must set the value to true." / "The server sets the value to true." / "If the value is false, follow these steps to change it to true." |

Recommended: Whether it's a brand new project or an existing one, perform the following steps.

## Timeless documentation (timeless-documentation)

Document the current version — how the product works right now, not how it changed from previous versions or might change in the future. This reduces maintenance and avoids assuming familiarity with earlier versions.

| Recommended | Not recommended |
| --- | --- |
| These subcommands let you interact with HTTP load balancing. | These new subcommands let you interact with HTTP load balancing. |
| The following command-line options aren't supported: | The following command-line options aren't currently supported: |

### Words to avoid (timeless-documentation)

When describing product or feature capabilities in product and reference documentation, avoid: *as of this writing*, *currently*, *does not yet*, *eventually*, *existing*, *future / in the future*, *latest*, *new / newer*, *now*, *old / older*, *presently / at present*, *soon*. They can prematurely disclose plans or imply change; they're implied (docs are assumed current unless a release version is specified); they become outdated fast; or they assume prior product knowledge. If you must use words like *new*, give a reference point such as a date or version release number — *The January 14, 2021 release of BigQuery includes a new resource panel.*

Exceptions: time-based words are OK in time-stamped content (press releases, blog posts, release notes — *Dataflow includes several new features.*) and in procedural content to emphasize a state change after a user step (*The VM goes offline soon after you send the shutdown command.*).

## Excessive claims (excessive-claims)

- Don't make performance or cost claims that aren't easily verifiable by the reader; reference the source of any specific performance claim (speed, storage, and so on). Judge against what might be true in the future, not just today.
- Avoid superlatives (*best*, *simplest*, *fastest*, *never*, *always*); use *ensure*/*guarantee* only when something can truly be ensured or guaranteed.
- Don't claim a product is secure or prevents attacks; say it "helps with security" or "is designed for security" — true even if an incident occurs.
- Avoid statements about third-party or competitive products that read as subjective or disparaging, or that can become untrue after the other company's next release.
- Safest: write factually and objectively, limited to verifiable information that stays true over the documentation's lifespan.

## Future features (future)

- Avoid documenting future features or products, even in innocuous ways. Don't pre-announce anything in documentation unless approved by your legal counsel.

## Inclusive documentation (inclusive-documentation)

- Avoid unnecessarily gendered language (*person-hours* not *man-hours*; *humanity* not *mankind*); use gender-neutral pronouns.
- Avoid idiomatic or figurative language and metaphors, including metaphorical senses of terms (*pets versus cattle*); use established, widely understood terms in their primary sense.
- Avoid ableist language (*crazy*, *insane*, *sanity-check*, *blind to*, *cripple*, *dumb*, *dummy*); choose a more accurate or alternative word for the context.
- Use diverse names, genders, ages, and locations in examples; avoid being too culturally specific to the US.
- For older adults, avoid *the elderly*, *the aged*, *seniors*, *senior citizens*, *80 years young*; use *older adults* or *aging population*, or mention relative age/relationship only when relevant.
- Don't refer to people in divisive ways (*native* vs. *non-native* English speakers); reconsider whether the distinction is needed and describe the feature in terms relevant to anyone.
- Avoid socially charged terms for technical concepts (*blacklist*, *native* feature, *first-class citizen*) even if still widely used.
- Don't describe people without disabilities as *normal* or *healthy*; use *nondisabled person*, *sighted person*, *hearing person*, *person without disabilities*, *neurotypical person*.
- Use the terms disability communities prefer — generally person-first (*people with disabilities*), but identity-first where communities prefer it (common in autistic, blind, and Deaf communities; capitalization varies — research the preference). Avoid *victim of*, *suffering from*, *wheelchair-bound* (use *experiencing*, *living with*, *uses a wheelchair*) and euphemisms like *physically challenged*, *special*, *differently abled*, *handi-capable*.

### Avoid graphic or metaphorical language (inclusive-documentation)

Avoid unnecessarily graphic or metaphorical language when a more precise term exists. Exception: an industry-established term with a specific technical meaning and no accurate synonym is OK (*terminate*, *execute*). A term like *STONITH* may be mentioned once when first explaining the feature, phrased to de-emphasize it.

Recommended: This approach might require you to fence failed nodes.

Sometimes okay: This approach might require you to fence failed nodes (sometimes referred to as *STONITH*).

| Recommended | Not recommended |
| --- | --- |
| If the connection doesn't respond, check for errors. | If the connection hangs, check for errors. |
| Point to **File**, and then click **New**. | Hover over **File**, and hit **New**. |

### Replace established terms (inclusive-documentation)

If replacing an established non-inclusive term (e.g., *whitelist*) could confuse readers, refer to the non-inclusive term once on first use, in parentheses, then use the inclusive replacement throughout. Often better: rewrite the sentence around the term entirely.

Recommended: To make sure that administrators get the notification, add them to an allowlist (sometimes called a *whitelist*). Anyone who isn't on the allowlist is blocked ...

Recommended: You can allow requests from a range of IP addresses by entering a CIDR block instead of a single address in the field.

### Write around non-inclusive code terms (inclusive-documentation)

When a non-inclusive term is embedded in code or keywords and can't be renamed (a cluster named `master`, the SQL keyword `SLAVE`): minimize use of the term, never outside code font. On first reference you can name the term, in code font, in parentheses if possible; afterwards use the preferred term (*parent node*, *replica*), with code formatting whenever the entity name or keyword itself is needed.

Recommended: The configuration file helps you create a parent node (which is named `master` in the file).

Recommended: Start the replica by using the `START SLAVE` statement.

## Jargon (jargon)

Jargon: specialized, often figurative group terminology (*camel case*, *swim lane*, *break-glass procedure*, *out-of-the-box*) and vaguely defined or overloaded terms (*solution*, *support*, *workload*). Exception: jargon can stay when readers search for the term (SEO) or it's widely understood and accepted by the industry or the document's audience. Decision flow:

- **Write around it** if not needed for SEO: instead of *Hold a post-mortem*, write *When the project is finished, review what processes worked or didn't work*; instead of *Create a back-of-the-envelope design*, write *Use an informal design process*.
- **Replace with a more specific term** per the word list: *affected area* or *spatial impact* (for *blast radius*), *import* or *load* (for *ingest*), *ready-made* or *pre-built* (for *off-the-shelf*). Word-list terms marked "Don't use" must be replaced or written around.
- **Used only once?** Describe it in plain language in parentheses, or link to a trusted definition.
  Recommended: You then move the task to an earlier part of the process (also known as *shifting left*).
- **Used throughout?** Briefly describe it in parentheses on first reference, or link to a trusted definition.
  Recommended: The application is in the same state as a *cold standby* (a backup or redundant system that's identical to a primary system).
- **In a command or code sample?** Use the word only in direct reference to the code items, formatted as code, and make clear what it refers to.
  Recommended: Add a user to the allowlist (`whitelist`) by entering the following: `whitelist adduser EMAIL_ADDRESS`.

## Writing for a global audience (translation)

Write with localization, translation, and internationalization in mind.

- Use simple words: *start*, *so*, *use* — not *commence*, *consequently*, *utilize*/*leverage*. Exception: OK when conveying a special sense (*Cloud Spanner utilizes up to 100% of the available CPU resources.*).
- Use a single word when it conveys the same idea as a phrase (*some*/*many*, not *a number of*).
- Write shorter sentences; long sentences impair understanding and raise translation cost.
- Avoid phrasal (compound) verbs when a simpler verb exists ("uses", not "makes use of"). Exceptions: *set up*, *log in*, *sign in*.
- Don't use too many modifiers; never more than two nouns modifying another noun.
- Place modifiers like *only* immediately before what they relate to; rephrase if still ambiguous.
- Use present tense and active voice; avoid complex or uncommon verb forms.
- Don't use the same word to mean different things, especially not as noun and verb in close proximity (watch *once*, *while*, *as*, *since*).
- Avoid directional language (*above*, *below*) in procedural documentation.
- Use qualifying nouns for technical keywords (the *`example.yaml` file*, not bare *`example.yaml`*).
- Define abbreviations; spell terms out whenever possible, at least on first use.
- Clarify antecedents: replace an ambiguous pronoun with the appropriate noun.
- Don't form plurals with *'s*, don't use plural or possessive forms of company/product/feature trademarks, don't use uncommon contractions.
- Address the reader as *you*, not *the user* or *they*. Exception: *the user* is OK for someone using the software the reader is developing.
- Provide context; don't assume the reader already knows what you're talking about.
- Avoid negative constructions when possible; tell the reader what they can do, not what they can't.
- Use the exact same term (including capitalization) for a concept everywhere; inconsistency causes different translations and raises cost.
- Use standard subject + verb + object order; keep subject and verb close to the start of the sentence.
- State the conditional clause before the instruction (circumstance first).
- Make list items parallel in structure with consistent capitalization and punctuation.
- Use bold and italics consistently; don't switch from italics for emphasis to underlining. Use consistent capitalization.
- Write dates and times in unambiguous and clear ways.
- Avoid culture-specific references — holidays, cultural practices, sports (unless certain they're known worldwide), colloquialisms/idioms/slang, humor, and geographically specific references like seasons.
- Use a diverse set of example names when you need people's names (for example, as email addresses).
- Use screenshots and text in figures sparingly — images aren't translated; convey new information in text, never only in a figure.

### Helper words and optional words (translation)

Repeat a word if the redundancy improves comprehension:

| Recommended | Not recommended |
| --- | --- |
| If the VM has started and if you're able to connect... | If the VM has started and you're able to connect... |

Use helper words such as *then*, *that*, and *of* — often dropped in conversational English — to avoid ambiguity:

| Recommended | Not recommended |
| --- | --- |
| If the attribute key is not found, then the default value is returned. | If the attribute key is not found, the default value is returned. |
| Start the profiler, and then run the app. | Start the profiler, then run the app. |

Don't omit relative pronouns (*that*, *which*):

Recommended: You can programmatically update the rules that you previously defined.

Not recommended: You can programmatically update the rules you previously defined.

### Standardized phrases (translation)

Use standardized phrases for frequently used sentences and introductory phrases. The standard phrases are defined on: cross-references (link introductions), placeholders (introducing output), and code-samples (introducing code samples).

## Voice and tone (tone)

- Aim for a conversational, friendly, respectful voice — casual, natural, approachable, like a knowledgeable friend — without slang, over-colloquialism, or frivolity; not pedantic or pushy.
- Don't write exactly the way you speak; aim conversational rather than formal, neither super-entertaining nor super-dry — the primary purpose is informing someone possibly in a hurry.
- Avoid where possible: buzzwords/jargon, cutesiness, figurative language, placeholder phrases (*please note*, *at this time*), choppy or long-winded sentences, starting all sentences with the same phrase (*You can*, *To do*), current pop-culture references, exclamation marks, wackiness/zaniness, phrasing that denigrates or insults any group, *let's* do something phrasing, *simply*/*It's that simple*/*It's easy*/*quickly* in a procedure, internet slang and abbreviations such as *tl;dr* and *ymmv*.
- Don't use *please* in instructions: "To view the document, click **View**", not "please click **View**".
- Self-editing: ask "What am I trying to say?"; ask a colleague when unsure; read aloud for naturalness; use sentence transitions; above all, communicate useful information clearly and directly — that matters more than perfect tone.
