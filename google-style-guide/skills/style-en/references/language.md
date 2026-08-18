# Language and grammar details

Covers: abbreviations, voice, capitalization, product-names, pluralization, possessives.

## Abbreviations (abbreviations)

Abbreviations include acronyms (pronounced as a word), initialisms (letters pronounced separately, like *CIA*, *FYI*, *PR*), shortened words (*Dr.*, *etc.*, *min*, *CA*), and contractions (covered separately). The technical acronym/initialism distinction rarely matters; *acronym* may refer to both.

- Short versions of words (*app*, *demo*, *sync*) are words, not abbreviations — no period after them. If unsure, use the speaking test: if you speak the short version as a word, treat it as a word.
- Use standard acronyms and initialisms that save the reader time; avoid abbreviating terms unrelated to the document's main topic; be wary of specialized abbreviations readers might not understand.

### When to spell out a term (abbreviations)

When an abbreviation is likely unfamiliar to the audience, spell it out on first mention with the abbreviation in parentheses immediately following:

Recommended: *Border Gateway Protocol* (*BGP*)

For all subsequent mentions, use the abbreviation by itself. If you use an abbreviation only once, include it only if it's as commonly used as the spelled-out term; otherwise don't include it.

- If the first mention occurs in a heading or title, you can use the abbreviation there and spell it out in the first paragraph that follows.
- Consider the audience: if the document will be translated, spelling out provides context for human and machine translation, and helps readers less familiar with English. If most readers will recognize the term, don't spell it out (developers don't need *application programming interface*; novices explaining the API concept might).
- Don't spell out a term when the expansion doesn't aid understanding (writing out *portable document format* doesn't help readers understand *PDF*).

These abbreviations rarely need to be spelled out:

- AI
- API
- DVD
- File formats such as PDF or XML
- HTML
- PC
- RAM
- REST
- Units of measurement such as MB, MiB, GB, or GiB
- URL
- USB

### Format abbreviation introductions (abbreviations)

- Italicize both the spelled-out term and its abbreviation: *Border Gateway Protocol* (*BGP*).
- Capitalize the spelled-out form only if it's a proper noun or conventionally capitalized — not merely because the abbreviation is uppercase: data manipulation language (DML), not Data Manipulation Language (DML).
- Include the abbreviation in link text when cross-referencing.

### Abbreviations not to use (abbreviations)

- Don't use *i.e.* or *e.g.*; use *that is* or *for example*, respectively.
- *etc.* is okay in some circumstances, but prefer different phrasing in most lists.
- Don't use internet slang abbreviations (*tl;dr*, *ymmv*, *RTFM*); write out what you mean non-figuratively.
- Use the most common form: spell out common, easily understandable words (*approximately*, not *approx.*).
- Spell out shortened words or symbols substituting for words (*10 times faster*, not *10x faster*).

### Periods with abbreviations (abbreviations)

- No periods with acronyms or initialisms.
- Period at the end of a shortened word, except for date and time abbreviations.
- No period after an abbreviation written or spoken as a word (*app*, *sync*).
- No period with abbreviations for countries, US states, or the District of Columbia (DC).

### Abbreviations as verbs (abbreviations)

Don't use acronyms, initialisms, or shortened words as verbs.

Recommended: Use SSH to log in to your remote shell.

Not recommended: Then ssh into your remote shell.

### Indefinite articles before abbreviations (abbreviations)

Use *a* before a consonant sound and *an* before a vowel sound; abbreviation pronunciation varies, so base the choice on the pronunciation most common for your audience. The word list fixes specific preferences: "a SQL", "a FHIR", "an SAP".

## Active voice (voice)

Use active voice and make clear who's performing the action; the grammatical subject should be the person or thing acting. Passive voice makes it hard for readers to figure out who's supposed to act (the reader, the computer, the server, an end user, a visitor).

Recommended: Send a query to the service. The server sends an acknowledgment.

Not recommended: The service is queried, and an acknowledgment is sent.

Passive with *by* names the actor but reads worse than active — whenever possible, make the doer the subject.

Not recommended: The service is queried by you, and an acknowledgment is sent by the server.

### Exceptions (voice)

Passive can be okay in these cases only:

- To emphasize an object over an action.

  Recommended: The file is saved.

- To de-emphasize a subject or actor.

  Recommended: Over 50 conflicts were found in the file.

  Not recommended: You created over 50 conflicts in the file.

- If your readers don't need to know who's responsible for the action.

  Recommended: The database was purged in January.

## Capitalization (capitalization)

Follow standard American English capitalization. Additionally:

- Don't capitalize unnecessarily; think about why (and whether) a word should be capitalized.
- Don't rely on a capitalization difference alone to convey meaning (Kubernetes *Pod* vs. generic *pod* is lost on casual or new readers).
- No all-uppercase except: official names, abbreviations always written in all-caps, or references to code that uses all-caps.
- No camel case except in official names or when referring to code that uses it.
- Don't name a casing style (*camel case*, *snake case*) — the names don't localize and aren't standardized; explain the requirement and give an example instead.

### Sentence case by context (capitalization)

Sentence case: capitalize only the first word, the first word of a subheading after a colon, and proper nouns or terms always capitalized a certain way. Apply it in every context:

- Titles and headings — sentence case, no period at the end.
- References to titles/headings from docs that follow this guide — sentence case even if the original uses title case; retain original capitalization for works that don't follow the guide.
- Figures — sentence case for captions and for labels, callouts, and other text in images and diagrams.
- Glossaries and indexes — lowercase terms unless a proper noun or otherwise requiring caps; sentence case for glossary definitions.
- Lists — sentence case for items in all types of lists.
- Tables — sentence case for all elements: contents, headings, labels, and captions.
- Hyphenated word starting a sentence or heading — capitalize only its first element, unless a subsequent element is a proper noun or proper adjective.

### Capitalization and colons (capitalization)

Lowercase the first word after a colon, unless the text is one of the following:

- A proper noun (*Open source software: Hadoop*)
- A heading
- A quotation (*Arthurian wit: "Bring me yon sworde"*)
- Text that follows a label such as *Caution* or *Note*

## Product names (product-names)

- Google product names take title case (every word capitalized except prepositions like *of*/*on* and articles like *a*/*the*), except when matching a UI label.
- Follow the official capitalization for names of brands, companies, software, products, services, features, and terms defined by companies and open source communities (e.g., in a Kubernetes context: "A Job creates one or more Pods").
- Keep officially-lowercase names lowercase even at a sentence start (macOS), but prefer revising the sentence to avoid that position.
- Feature names are generally lowercase; capitalize only if officially capitalized, follow precedent set by other documents if unsure, and match the UI label when referring to one.
- Use the full trademarked product name; don't abbreviate or shorten it except when matching a UI label — then make clear you mean the Google product. Once a product is established, consider a more general term (*a service mesh* after establishing *Anthos Service Mesh*).
- It's OK to call Google products services (*the Compute Engine service*) unless *services* creates ambiguity — then use product names.
- Don't use product or feature names as verbs.

### Articles before product names (product-names)

Don't use *the* before a product name unless the name modifies something else. *Do* use *the* before tool and API names.

Recommended: Using Cloud Datastore with Cloud Dataproc

Recommended: The Cloud Datastore options page

Recommended: The Google Cloud console

Recommended: The Transcoder API

Recommended: The `gcloud` CLI

Not recommended: Using the Cloud Datastore with Cloud Dataproc

If you use a product name as a modifier with an indefinite article (*a* or *an*), pay close attention to which article precedes the product name.

## Pluralization (pluralization)

- Follow standard US English pluralization; use regular plural forms. Avoid *'s* plurals — they read as possessives or contractions and can cause translation issues.
- With long or complex subjects, and with compound subjects joined by *and* or *or*, match the verb number to the subject.
- Use a plural after *one or more* ("If one or more tests fail"); rewording is sometimes clearer ("If any one test fails").
- Use a singular after *more than one* ("more than one instance").
- Pluralize abbreviations as regular words (APIs, not API's); add *es* when the abbreviation ends in *s*, *sh*, *ch*, or *x* (*OSes*, *DISHes*, *DCCHes*, *BMXes*).
- Match number between a spelled-out term and its abbreviation: virtual machines (VMs), not virtual machines (VM).
- With spelled-out units, singular only when the number is exactly 1; plural for all other numbers including 0 and decimals (0 degrees, 0.5 degrees, 1 degree).
- Don't pluralize a unit abbreviation used with a number (64 GB, not 64 GBs); put a space (preferably nonbreaking) between number and unit. Spelling out *-bit*/*-byte* terms can help but is generally unnecessary with a specific number.
- Don't form a plural of a product, feature, or company trademark.
- Keep class names singular; never pluralize the class name itself — add a plural noun after it (`Intent` objects, not `Intent`s or `Intents`); manual plurals might cause translation issues.
- No optional plurals in parentheses (key(s), child(ren)); pick singular or plural and stay consistent, or use *one or more* if both matter.

## Possessives (possessives)

- Singular nouns, including those ending in *s*, take *'s* (the storage class's quota); plural nouns ending in *s* take only an apostrophe (the models' capabilities); plural nouns not ending in *s* take *'s*.
- If a possessive reads awkwardly, rewrite to omit it ("The rule that the Federal Trade Commission (FTC) issued", not "The Federal Trade Commission's (FTC's) rule").
- Don't form a possessive from a feature name, product name, or trademark — regardless of who owns it — when describing function or performance; use the name as a modifier or rewrite with *of* ("the performance of Google Search").
- A company name can take *'s* when referring to the company itself (Google's new office), but not when the name is used as a trademark.
- Don't form the possessive of a code item; attach the possessive to the noun that follows it or rewrite ("the `wordCount` method's return value", or "the value returned by the `wordCount` method").
