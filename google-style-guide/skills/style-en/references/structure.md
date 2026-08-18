# Structure: lists, procedures, tables, headings

Covers the slugs: lists, procedures, tables, headings.

## Lists (lists)

### List type selection

- Don't use a list to show only one item; a single item isn't really a list — set it off with some other formatting.
- Lists and tables both present sets of similarly structured items; see the decision table under Tables below.
- **Numbered list** (`ol`): sequence is significant (ordered steps, phases, priorities). Nested sequential lists are labeled with lowercase letters, then lowercase Roman numerals.
- **Bulleted list** (`ul`): not a sequence (nonsequential options or examples). Make it clear whether every item is required.
- **Description list** (`dl`, `dt`, `dd`): terms each with a description/definition/explanation; draws attention to two or more terms (such as a glossary).
- **Description list with bulleted run-in headings** (`ul`): terms or phrases each followed by a description; use to highlight and explain several concepts or save space.
- List items can contain multiple paragraphs; use `p` elements, not `br`.
- Reverse-numerical order: `ol` with the `reversed` attribute. Manual numbering via `value` is usually a bad idea (renumbering burden), though occasionally convenient.
- Parallel syntax: use the same syntax/structure for all items in a list, if possible.

### Introductory sentences for lists

- In most cases precede a list with an introductory sentence: colon if it immediately precedes the list, period if material (such as a note paragraph) intervenes.
- Exception: if the immediately preceding heading gives enough context, no introductory sentence is needed.
- Always a complete sentence — never a partial sentence completed by the list items. *The following* as a noun phrase is fine.

Recommended: To get the USB driver, follow these steps:

Not recommended: To get the USB driver:

Heading exception: under a heading "Objectives", list the objectives directly; don't add "In the following tutorial, you will complete the following tasks:".

### Capitalization and end punctuation

**Numbered, lettered, bulleted lists.** Capitalize each item, unless case is an important part of the information — such as glossary terms. End each item with a period (or other sentence-ending punctuation), except when the item: is a single word; has no verb; is entirely in code font; is entirely link text or a document title. If punctuation ends up inconsistent, rewrite for parallel construction or punctuate every item.

Recommended (single words, no periods): The following words are adjectives: Big / Small / Gratuitous

Recommended (sentences, periods): You can do any of the following by using the API: Create an item. / Replace one item with another. / Update an item. / Delete an item.

**Description lists.** Don't add an explanatory phrase to only one list item; convert to a description list with explanatory phrases for all items. In most contexts capitalize each term (`dt`). Don't end the term with a period; do generally end each `dd` description with a period.

Not recommended (explanatory phrase on one item only): Big / Relevant / Gratuitous / Purple—this is a color.

**Run-in headings.** In most contexts:

- Capitalize the run-in heading; end it with a period or a colon, consistently within the list. Bolding that punctuation is a per-page-consistency choice.
- After a period, the description starts with a capital letter and ends with a period.
- After a colon, the description starts lowercase; no period if it's a list of items or short phrases without verbs, a period if it includes a verb or expresses a standalone thought.
- Never use a dash to set off the description.

Recommended (colon style): **Big**: a short word / **Relevant**: a fancy word / **Gratuitous**: a long word / **Purple**: a vibrant color

### Comma-separated lists

Use serial commas. Avoid ending with *etc.* or *and so on*; signal non-exhaustiveness in the introduction instead.

Recommended: The service processes data like event logs, clickstream data, social network interactions, and e-commerce transactions.

## Procedures (procedures)

A procedure is a sequence of numbered steps for accomplishing a task.

### Introductory sentences

- In most cases introduce a procedure with a sentence providing context that isn't in the heading. Don't repeat the heading: if the heading explains the procedure and no additional context is needed, include no introductory statement.
- Colon if it immediately precedes the procedure; period if material intervenes. An imperative statement is fine.
- Never a partial sentence completed by the numbered steps.

Recommended: To customize the buttons, follow these steps:

Also recommended: Customize the buttons:

Also recommended: To customize the buttons, do the following:

Not recommended: To customize the buttons:

### Single-step procedures

Write a one-step procedure as one sentence formatted as a bulleted list item — not a numbered step, and not an intro plus a bullet.

Recommended: - To clear (flush) the entire log, click **Clear logcat**.

Not recommended: To clear (flush) the entire log, follow this step: 1. Click **Clear logcat**.

### Sub-steps

Sub-steps get lowercase letters; sub-sub-steps get lowercase Roman numerals. Treat a step with sub-steps like an introductory sentence: end it with a colon or period as appropriate ("1. To add a VM instance, do the following: a. Click **Create instance**. b. For **Name**, enter a name, and then do the following: i. ... c. Click **Create**.").

### Order of multiple components in a step

1. Describe the action to take.
2. List a command, if necessary.
3. Explain any placeholders used in the command.
4. Explain the command in more detail, if necessary.
5. List the output of the command, if necessary.
6. In a separate paragraph, explain the result of the action, or any output, if necessary.

(Example: "Plan the Terraform deployment:" → `terraform plan -out=NAME` → "Replace `NAME` with the name of your Terraform plan." → command detail → output → "The output shows what resources to add, change, or destroy.")

### Multi-action steps, multiple and repeated procedures

- One step per action in general, but combine sequential menu selections with angle brackets: "Click **File > New > Document**." Split steps that feel too long.
- More than one way to complete a task: document one procedure accessible to all readers; if all are accessible, pick the shortest and simplest. Prefer keyboard-only, the shortest, and the language most of the audience knows. Multiple ways, if needed, go in separate pages, headings, or tabs.
- Don't repeat procedures; reference and link to them ("Create a user as you did in the previous step.").

### Optional steps

Begin with *Optional* and a colon.

Recommended: 1. Optional: Type an arbitrary string ...

Not recommended: 1. (Optional) Type an arbitrary string ...

### Location before action

State where the reader completes an action (tool, UI field) before the action. When a set of procedures is split across multiple headings, restate the location in each procedure, even if unchanged.

Recommended: 1. In Google Docs, click **File > New > Document**.

Not recommended: 1. Click **File > New > Document** in Google Docs.

### Steps with goals

State the goal before the action.

Recommended: 1. To start a new document, click **File > New > Document**.

Not recommended: 1. Click **File > New > Document** to start a new document.

If the "To ..." format could imply a required step is optional, use the colon format:

Recommended: 1. Start a new document: click **File > New > Document**.

Usually context makes requiredness clear, and "To ..." is more natural. To decide, relate the step's goal to the procedure's: in a bar-chart procedure "To create the chart" is clearly required, but "To sort the data by date" might or might not be — write "Sort the data by date:" to clarify it isn't optional.

### Steps with results or justifications

- Action first, result second, in the same paragraph — but avoid repetitiveness and heavy bolding by folding the result into the next step.
- Justifications likewise follow the action.

Recommended: 1. Click **Run**. The query results appear after the query runs.

Recommended: 1. Click **Enter**. 2. In the **New file** dialog that appears, click **Next**.

Not recommended: 1. Click **Enter**. The **New file** dialog appears. 2. In the **New file** dialog, click **Next**.

Recommended (justification): 1. Store the private key in a secure location. You need it later.

### Summary of guidelines

- First sentence of a step includes an imperative verb.
- Use complete sentences; use parallel structure and consistent verb form.
- Set the context (tool or environment); restate it in the first step under each heading even if unchanged. ("In Cloud Shell, connect to the development cluster.")
- Write in the order the reader follows: location before action, goal before action.
- No directional language (*above*, *below*, *right-hand side*) — bad for accessibility and localization; if a UI element is hard to find, provide a screenshot. "In the preceding diagram,..." / "In the following diagram,..." are the accepted forms.
- Don't use *please*.
- Avoid *run the following command*; focus on what the command does. (Recommended: "In Cloud Shell, deploy the load generator:...")
- If the reader must press **Enter** after a step, include that in the same step. ("Click the search box, type `custom function`, and then press **Enter**.")
- No keyboard shortcuts.
- When there's more than one way, give only the best way.
- Give preparation information ahead of the task ("The following hardware and software are required:...").
- Include as few steps as possible; limit interruptions in the path.
- One reader decision at a time: each instruction is a separate list item.

## Tables (tables)

### List or table?

| Item type | How to present |
| --- | --- |
| Each item is a single unit (language names, steps to follow). | Numbered, lettered, or bulleted list. |
| Each item is a pair of pieces of related data (term/definition pairs). | Description list (or, in some contexts, a table). |
| Each item is three or more pieces of related data (parameters with name, type, description). | Table. |

### Places not to use tables

- Not for page layout; use the site's standard CSS.
- One row: usually not a table — but in some contexts (especially layout consistency in reference documentation) it might be.
- One column: use a list instead.
- Not for laying out code snippets.
- Don't split long one-dimensional lists into multiple columns to save space; tables are only for two-dimensional data that semantically makes sense in rows and columns.
- Avoid tables in the middle of a numbered procedure.
- Cells can contain multiple paragraphs; use `p` elements, not `br`.

### Introductory sentences and placement

- Introduce a table with a complete sentence describing its purpose (not all screen readers preannounce tables): colon if it immediately precedes the table, period if material intervenes.
- Refer to the table's position with *the following table* or *the preceding table*.
- Don't put a table in the middle of a sentence. Avoid footnotes; if used, place them immediately after the table.

Recommended: Change the environment variables to values for your deployment, as listed in the following table:

### Table captions

- A document's only table needs no caption — but keep the table adjacent to the text that refers to it.
- Multiple tables in fairly close proximity: caption each with a `caption` element as the first child of `table`, in the form "**Table NUMBER.** DESCRIPTION". Sentence case; no period at the end.
- Refer to tables by number in text — *... as shown in table 2*; capitalize *table* only at the start of a sentence.

Recommended: `<table><caption><b>Table 1.</b> Prehistoric birds</caption>...</table>`

### Table formatting and column heads

- Don't style the `table` element; don't convey a header row/column by visual style alone — mark headers semantically with `th`.
- Don't merge cells; no `colspan` or `rowspan`.
- Sort rows logically, or alphabetically if there's no logical order; split long or complicated tables (multiple header rows/columns).
- Don't present new information through images or symbols alone; always provide a descriptive `alt` attribute.
- Column heads: sentence case, concise, no end punctuation (no period, ellipsis, or colon). Use `th` for the first column and first row only; include the `scope` attribute for accessibility.
- Where possible use table CSS that adapts to viewport sizes; avoid linking to tables — refer by table number.

## Headings (headings)

- Use sentence case for all headings and titles.
- Make headings and titles descriptive and unique so readers can jump between pages and sections.
- Title the document by its primary purpose (a tutorial with a conceptual introduction still gets a task-based title); phrase each section heading by that section's content type. Mixing task-based and conceptual heading styles in one document is OK.
- Task-based heading: start with a bare-infinitive (base form) verb. Recommended: Create an instance. Not recommended: Creating an instance.
- Conceptual heading: a noun phrase not starting with an *-ing* verb. Recommended: Migration to Google Cloud. Not recommended: Migrating to Google Cloud.
- Section not required for all users or scenarios: *Optional:* prefix. Recommended: Optional: Customize your alias. Not recommended: Customize your alias (optional).
- Unique `h1` per page, used only once; don't repeat the exact page title in a section heading (page *Create and start VM instances*, sections *Create a VM* and *Start a VM*).
- Avoid *-ing* verb forms (present participle or gerund) as the first word of any heading or title — inconsistently translated, longer. Recommended: Transfer data sets. Not recommended: Transferring data sets. Exceptions: gerunds with no better alternative (Billing, Pricing); *-ing* later in the heading is OK (*Introduction to BigQuery monitoring*).
- Keep punctuation simple; punctuation can signal the heading is too complicated — consider rewriting.
- Abbreviate a word in a title or heading only if the abbreviation is the more commonly known version; define it at the first instance of the word in a paragraph. Defining it in the title/heading is allowed, but consider whether the added length adds value; for SEO, use the more prominent form.
- No numbers in headings to indicate section sequence; rely on hierarchy and order.
- Avoid code items in headings; if unavoidable, add a descriptive noun to the code-font item.
- No links in headings — easily confused with heading styling.
- Apply heading tags hierarchically without skipping levels (`h3` only under `h2`); never use heading levels or made-up formatting for visual styling — use CSS.
- No empty headings; content must follow every heading before the next one.
- Introduce a group of related lower-level sections with *the following sections* — never the ambiguous *this section* or *these sections*.
- Guidance for standard text (contractions, articles) also applies to headings.
