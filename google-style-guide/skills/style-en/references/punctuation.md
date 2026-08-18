# Punctuation

Covers: commas, periods, quotation-marks, hyphens, format-examples, colons, semicolons, slashes, dashes, ellipses, parentheses.

## Commas (commas)

### Serial commas

In a series of three or more items, use a comma before the final *and* or *or* (serial/Oxford comma).

- Recommended: Locations are divided into zones, regions, and multi-regions.
- Not recommended: Locations are divided into zones, regions and multi-regions.

### After introductory words and phrases

In general, place a comma after an introductory word or phrase.

- Recommended: Finally, only groups that contain parameters appear in this list.

### Two independent clauses

When a coordinating conjunction (*and*, *but*, *or*, *nor*, *for*, *so*, or *yet*) separates two independent clauses, insert a comma before the conjunction — unless both clauses are very short.

- Recommended: The libraries make feed creation easier, and they ensure that only valid feeds are produced.
- Recommended (both clauses very short): Type your ID and click **OK**.

### Independent from dependent clauses

When an independent clause and a dependent clause are joined by a coordinating conjunction, insert a comma *only if* the sentence could be misunderstood without one.

- Recommended (no comma needed): Direct-access flags are plain variables and can be read directly.
- Recommended (comma prevents misreading): The manager acknowledged the last team member who entered the room, and started the meeting.

### Set off other kinds of clauses

- In general, put a comma before *which* at the start of a nonrestrictive clause: "Name of the group, which has a maximum length of 200 characters."
- Put a semicolon, period, or dash before a conjunctive adverb (*otherwise*, *however*, *therefore*), and a comma after it: "The variable must have a value; otherwise, the server returns an error."
- Don't put a comma before the causal conjunction *because* unless it starts a nonrestrictive clause

## Periods (periods)

End a complete sentence with a period, unless it's a question. List items have their own end-punctuation rules (see the Lists page).

### Periods with URLs

A period right after a URL or file path can look like part of the URL. Techniques:

- Whenever possible, avoid putting URLs in text.
- Rewrite the sentence so the URL isn't at the end.
- Put the URL on a separate line from the text, omitting the final period.

When you do put a period after a URL, don't leave any space between the URL's last character and the period.

### Periods with quotation marks

Place a sentence-ending period inside the quotation marks even if it isn't part of the quoted material. Exception: quotation marks around a keyword or other literal string take the punctuation outside (see Quotation marks below).

If the material inside the quotation marks ends with a question mark or exclamation point, don't add a period: Children always ask "Why?"

### Periods with parentheses

If the last part of a sentence is inside parentheses, put the period after the closing parenthesis. If the parentheses contain a complete standalone sentence, put the period inside.

- Recommended: App Engine applications are easy to create, easy to maintain, and easy to scale. (With App Engine, there are no servers for you to maintain.)

### Other period rules

- Don't end headings with periods.
- Use a period as the decimal point (not a decimal comma).
- Put a period after a shortened word; no periods between the letters of an acronym or initialism.
- Leave only one space between sentences.

### Exclamation points

In general, avoid exclamation points — they can appear unprofessional, alarming, or translate poorly. Never in concept and reference docs; avoid in procedures (use periods for completion steps: "The VM is created."); acceptable in blog posts to convey enthusiasm, but not in every paragraph. Acceptable uses: code syntax that requires them (the `!=` operator), exact system literals (error codes, log messages), and sparingly in tutorials to mark major milestones ("Congratulations! You've completed the setup.").

## Quotation marks (quotation-marks)

### When to use quotation marks

Outside code, use quotation marks sparingly. Use them for titles of shorter works (articles, episodes in a web series) unless they're part of a link; use italics for most full-length works. Cases in regular text:

- A section of a larger document or piece, when you can't link to the section directly: The technique is described in the section "Deploying containers" of the Containers overview video.
- The title of a parent document when you're already linking to a section.
- Directly citing a person or quoting a slogan or motto.
- A term used metaphorically, only if it's not an established usage in the domain (an "island" within the network).

### Commas and periods with quotation marks

Commas and periods go inside quotation marks.

- Recommended: See the section titled "Care and feeding of the emu."

**Exception**: When a keyword or other literal string is in quotation marks, put any other punctuation outside — the quotes mark an exact literal string, so don't add anything extraneous inside them. However, in general, don't put quotation marks around an item that's in code font, unless the quotation marks are part of the item.

- Recommended: If you enter `escape`, the program crashes.
- Acceptable: If you enter "escape", the program crashes.
- Not recommended: If you enter "escape," the program crashes.

### Straight and curly quotation marks

Always use straight quotation marks and straight apostrophes, never curly/typographic marks. Code requires straight marks, and curly marks are hard to verify when proofreading.

### Single quotation marks

Use single quotation marks only in code examples (in languages that use them) or for a quotation nested inside a double-quoted quotation.

## Hyphens (hyphens)

Use a hyphen when needed for clarity. Hyphenation depends on location (before a noun vs. after a verb), readability, and convention. When unsure, check in order: (1) the documentation set's established convention, (2) the style guide's word list, (3) the Merriam-Webster dictionary. Deviate when it serves readers.

### Prefixes

In general, don't use a hyphen between a prefix and the main noun: *infrastructure*, *metadata*, *preprocessing*, *pseudocode*.

Add a hyphen after a prefix when:

- The prefix is *self* or *cross*: *self-managing*, *cross-region*
- The noun is capitalized or is a number: *non-Google*, *post-2000*
- Needed to avoid confusion or difficulty in reading: *de-energize*, *intra-index*, *re-mark*, *re-sign*
- The base term already has hyphens or spaces: *un-Google-like*, *non-twentieth-century*
- Needed for consistency within a document: *pre-processing*, *post-processing*

### The non prefix

*Non* follows the same guidelines but easily forms hard-to-parse words, so it's often hyphenated. Use judgment plus in-document consistency. Contrasting accepted usages:

- Recommended: *noncurrent*, *nonempty*, *noninteractive*, *nonpublic*
- Recommended: *non-existence*, *non-integer*, *non-key*, *non-managed*

Always add a hyphen when *non* precedes a hyphenated compound word: *non-KSA-based*, *non-self-sustaining*.

### Compound nouns

In general, write compound nouns closed (one word): *webpage*, *hostname*, *tradeoff*, *workaround*. If Merriam-Webster uses the two-word or hyphenated form but the closed form is the predominant convention in your context or trending that way, use the closed form. The word list has exceptions for well-established hyphenated or spaced terms (*multi-region*, *style sheet*); noun, verb, and adjective versions of a word may be treated differently.

When the components of a unit of measurement are multiplied by each other, hyphenate them: *5 vCPU-hours*, *40 person-hours*.

### Compound modifiers before a noun

If needed for clarity, hyphenate compound modifiers before a noun. This is subjective, but apart from the exceptions below, it's almost never wrong to hyphenate a compound before a noun for clarity.

- Recommended: A well-designed app
- Recommended: Android-specific techniques

Use a hyphen after *more* or *most* if needed to clarify what those words modify: "Edge locations with more-reliable internet links."

Avoid compound modifiers of more than two words; move some words after the noun. If you must use one, hyphenate between each word as needed for clarity.

- Recommended: cross-data-center replication
- Not recommended: edition-2023-specific test cases

### Numbers and units of measurement

Hyphenate a number and a spelled-out unit of measurement that together modify a noun: *a 64-bit system*, *100,000-byte files*, *a five-minute wait*.

Don't hyphenate if the unit is abbreviated, unless the hyphen is needed for clarity; use a nonbreaking space (`&nbsp;`) between number and unit instead: `200&nbsp;GB disk` (200 GB disk).

### Exceptions for modifiers

Don't hyphenate adverbs ending in *-ly*, except when needed for clarity.

- Recommended: Publicly available implementations
- Not recommended: Publicly-available implementations

Don't hyphenate compounds that are conventionally not hyphenated (follow the word list or the doc set's convention): *a managed instance group (MIG)*, *a machine learning model*.

### Compound terms after a verb

In general, don't hyphenate a compound that follows a verb.

- Recommended: The app is well designed.
- Recommended: The logs are written in real time.
- Recommended: Customers can use the utility as is.

Exception: some compound terms are always hyphenated, even after a verb — for example, *on-premises*, *add-on*, *cloud-based*, *cloud-adjacent*, *customer-facing*, *user-friendly*, *game-like*. Check the word list, then Merriam-Webster; follow the documentation set's convention.

- Recommended: You can deploy the app on-premises.
- Recommended: The app is designed to be user-friendly.

### Ranges of numbers

Use a hyphen, not an en dash, for a range of numbers. If a hyphen introduces ambiguity, use words such as *from*, *to*, and *through*. Don't mix hyphens with words.

- Recommended: 8-20 files
- Recommended: from 8 to 20 files
- Not recommended: from 8-20 files

### Spaces and suspended hyphens

Never place a space on either side of a hyphen, except after (never before) a suspended hyphen. When compound modifiers share a base, you can drop the base from all but the last modifier, keeping the hyphens.

- Recommended: You can set up the system to scan for new files at one- or two-hour intervals.

## Format examples (format-examples)

Introduce examples with *such as*, *for example*, or *like*:

- Short-to-medium example at the end of a sentence: set it off with a comma, parentheses, or an em dash as appropriate. Avoid a semicolon for this purpose.
  - Recommended: Choose a strong encryption algorithm, such as AES-256.
- Example in the middle of a sentence: keep it relatively short, set off with dashes, commas, or parentheses as appropriate.
  - Recommended: Enter a six-digit hex number (for example, `228B22`), and then click **OK**.
  - Not recommended: Enter a six-digit hex number (for example, if you want the color forest green, enter `228B22`), and then click **OK**.
- Longer example: introduce it as a separate sentence, using *for example* as an adverb in that sentence.
  - Recommended: You can assign tags to your virtual machine instances to categorize them. For example, you could tag instances by environment with `env:prod` or `env:dev`.

## Colons (colons)

- Text that precedes a colon introducing a list must be able to stand alone as a complete sentence.
  - Recommended: The fields are defined as follows:
  - Not recommended: The fields are:
- In general, lowercase the first word after a colon within a sentence (exceptions are on the Capitalization page).
  - Recommended: Tone: concise, conversational, friendly, respectful

## Semicolons (semicolons)

If possible, avoid semicolons. A semicolon is preferred when:

- Joining two closely related independent clauses where a period or comma is not as effective.
- Preceding a conjunctive adverb (like *therefore*) or a phrase (like *that is*) that joins two independent clauses.
- Separating a series of long or complex items that contain their own punctuation.
  - Recommended: Review your document one more time, checking for the following: present tense and active voice; typos, punctuation, and grammar; and whether you can shorten anything.

## Slashes (slashes)

Avoid slashes, except in code.

- Don't use date formats that rely on slashes.
- Don't use slashes to separate alternatives.
  - Recommended: Call this method five or six times.
  - Not recommended: Call this method 5/6 times.
- Avoid *and/or*: *and* often implies *or*; if you need both, write "X, Y, or both" — except when space is limited, such as in tables.
- Use forward slashes, as appropriate, in file paths and URLs. Break a too-long URL immediately after a slash; never insert an extraneous hyphen to break a URL.
- Don't write fractions with slashes (3/4 is ambiguous). Recommended: ¾, 0.75, 75%.
- Don't use abbreviations that rely on slashes; spell the words out. Recommended: care of, with. Not recommended: c/o, w/.

## Dashes (dashes)

- To indicate a break or interruption in the flow of a sentence, use an em dash, with no space before or after it.
- Don't use an en dash or a hyphen (even with spaces around it) in place of an em dash. Type the em dash as `&mdash;` in HTML or with OS key sequences.
- Don't use en dashes at all; use a hyphen or the word *to* instead.
- Don't separate an item and its description with a spaced dash or hyphen; use a colon or a period, and an HTML description list (`<dl>`) for a series.
  - Recommended: Example: This is an example.
  - Not recommended: Example - This is an example.

## Ellipses (ellipses)

- In general, don't use ellipses in documentation: omit unnecessary information and include all necessary information.
- Don't use ellipses as suspension points to indicate hesitation.
- When ellipses appear in a user interface, exclude them from the documentation describing the UI, unless their omission could cause confusion. If the button reads **Save...**, document it as *click **Save***.
- Ellipses are acceptable in quoted text to replace a portion of it, but never at the beginning or end of the quote. When the omitted material contains one or more sentence boundaries, use four dots instead of three (the final point is the period).
- Build an ellipsis as three contiguous periods (not the ellipsis character), with one space before and after — unless a punctuation mark immediately follows, in which case no space after.
  - Recommended: You don't need to understand all the other Python code in there... we'll explain it all in class.

## Parentheses (parentheses)

- Some readers ignore anything in parentheses, so don't put important information in parentheses if you can help it. Consider whether commas, dashes, semicolons, or periods work as well.
- If you use parentheses mid-sentence, keep the parenthetical thought short; otherwise, consider two sentences.
- If a full standalone sentence appears inside parentheses, the period goes inside the parentheses, not outside.
- Don't use parentheses to indicate optional plurals.
- Recommended: Enter a name for the instance—for example, `my-instance-99`.
- Not recommended: Enter a name for the instance (for example, `my-instance-99`).
