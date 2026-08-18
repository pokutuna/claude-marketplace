# Code in text, API reference, code samples

Covers: code-in-text, api-reference-comments, code-samples.

## Code in text (code-in-text)

In ordinary text sentences, use code font (HTML `code` element; Markdown backticks) for most things that have anything to do with code — text meant to be entered verbatim, or names of code entities. Code font signals verbatim entry, shows its boundaries, and separates the entity from surrounding text.

### Items to put in code font

Not an exhaustive list. Put these in code font: attribute names and values; class names; command output; command-line utility names (such as `gcloud`, `gsutil`, `kubectl`, and `bq`); data types; database elements (such as row and column names); defined (constant) values for an element or attribute; DNS record types; element names (HTML and XML); enum (enumerator) names; environment variable names; filenames, filename extensions (if used), and paths; folders and directories; HTTP content-type values; HTTP status codes; HTTP verbs; IAM role names; IP addresses; language keywords; method and function names; namespace aliases; placeholder variables; package names; port numbers; query parameter names and values; strings (such as URLs or domain names) that are used in commands and code; text input; UI elements that are rendered based on previously entered text (such as a server or instance name).

Examples:

- The `SnapshotDiskOperator` class includes the `generate_snapshot_name` method.
- Nested data is represented as a `STRUCT` type.
- The constant `city` has the value `"San Francisco"`.
- Open the `pg_hba.conf` file, which is typically in the `/etc/postgresql/13/main` directory.
- Replace `SUBNETWORK_NAME` with the resource ID of the private subnet that you want the blueprint to use.
- In the **Key name** field, enter `config-management`.
- From the **Server name** list, select **`my-sql-cluster1`**.

- When you refer to an HTML or XML element name, don't put angle brackets (`<>`) around it.
- Generally, don't put quotation marks around code unless the quotation marks are part of the code.

### Items in ordinary (non-code) font

Not exhaustive. Exception: if you refer to any of these as computer input or output, or as a code entity (an attribute or value), use code font.

- Domain names: "The test environment is designed only for standard application offerings from example.com."
- Names of products, services, and organizations.
- URLs the reader is supposed to follow in a browser — usually best formatted as a link with descriptive link text instead of exposing the URL.

### Code in UI elements

If a UI element meets the requirements for code font, use both code font and bold.

Recommended: In the **Network** list, select **`my-net-2`**.

Recommended: In the **Query results** pane, the **`Store`** column is displayed.

### Items sometimes in code font

- **Boolean values.** A direct reference to a Boolean data-type value (such as `true` or `false`, or `1` or `0`) is code font. The evaluation of a Boolean condition as true or false is non-code font.
  - Recommended: If the update succeeds, returns `true`.
  - Recommended: `enableCertificateValidation`: If true, validates the SSL certificate before proceeding. If false, trusts the certificate without validating it.
- **Command-line utility names.** When a utility is spelled the same as its software project or product (capitalization aside), use code font for the command and ordinary font for the project or product name.
  - Recommended: Invoke the GCC 8.3 compiler using `gcc` for C programs or `g++` for C++ programs.
  - Recommended: The options for the `curl` command are explained on the curl project website.
- **Email addresses.** Code font when used as computer input or output; non-code font and hyperlinked when a way to contact someone.
  - Recommended: Enter the username, not the full email address. For example, enter `alex`, not `alex@example.com`.

### Method names

When referring to a method name in text, omit the class name except where including it would prevent ambiguity.

Recommended: To retrieve the zebra's metadata, call its `get` method.

Not recommended: To retrieve the zebra's metadata, call its `animal.get` method.

### HTTP status codes

Call it a *status code*, never a *response code* or *error code*. Single code: number and name both in code font — "an HTTP `400 Bad Request` status code". You can leave out "HTTP" if it's implicit from context. Range: use *Nxx* with a specific digit in place of N to mean anything in the N00–N99 range — "an HTTP `2xx` or `400` status code" — number in code font even when the code's name is omitted. Exact range: "an HTTP status code in the `200` - `299` range" (numbers in code font).

### Grammatical treatment of code elements

Don't use code elements (keywords, filenames) as English verbs or nouns, and don't inflect them (plural, possessive, -ing). Include a noun after the element name and inflect that noun.

| Recommended | Not recommended |
| --- | --- |
| The `ADDRESS` constant's value is defined in the `settings.h` file. | `ADDRESS` 's value is defined in `settings.h`. |
| To add the data, send a `POST` request. | `POST` the data. |
| To retrieve the data, send a `GET` request. | Retrieve information by `GET` ting the data. |
| You can't call the `close` method for a file before you call `open`. | `Close` ing the file requires you to have `open` ed it first. |
| Takes an array of extended ASCII code points (an array of `INT64` values) and returns `BYTES` values. | Takes an array of extended ASCII code points (ARRAY of INT64) and returns BYTES. |

### **[Android]** Linking API terms

In code comments turned into generated reference docs: link the first instance of each Android API element per section (code font + HTML `a` element); later uses in the same section get code font, no link. Very common classes such as `Activity` and `Intent` don't need linking every time. Terms used as concepts rather than classes — activity, service, fragment, view, loader, action bar, intent, content provider, broadcast receiver, app widget — are lowercase, non-code, unlinked; an actual instance uses the formal class name linked to its reference page. Link formats: class name as link text; method name as fragment identifier (add the class name for static methods; full signature to distinguish overloads); widget/layout XML attributes use the fragment identifier `#attr_android:ATTRIBUTE_NAME`.

## API reference code comments (api-reference-comments)

### Coverage requirements

The API reference **must** describe:

- Every class, interface, struct, and similar member (such as union types in C++).
- Every constant, field, enum, and typedef.
- Every method, with a description for each parameter, the return value, and any exceptions thrown.

Extremely strong suggestions (may not make sense for a particular API or language):

- Include a code sample (~5-20 lines) at the top of each unique page (class, interface, etc.).
- Put all API names, classes, methods, constants, and parameters in code font, and link each name to its reference page (most doc generators do this automatically).
- Put string literals in code font, enclosed in double quotation marks — for example, `"wrap_content"` or `"true"`.
- Spell class names exactly as in code (`ActionBar`). Don't pluralize class names (`Intents`, `Activities`); add a plural noun instead (`Intent` objects, `Activity` instances). Exception: a class whose name is a common term may be referred to with the lowercase English word, not in code font (activities, action bar).

### Classes, interfaces, structs

First sentence: briefly state the purpose or function with information not deducible from the name and signature; keep it unique, descriptive, and short (many tools extract it for a class list). Don't repeat the class name, don't say "this class will/does...", and don't use a period before the sentence's end (write *for example*, not *e.g.*) because some generators truncate the short description at the first period. Elaborate afterward on how to use the API, key features, and best practices or pitfalls.

### Members

Make constant and field descriptions as brief as possible; link to relevant methods that use them.

### Methods

First sentence states what action the method performs. Subsequent sentences explain why and how to use it, prerequisites, exceptions that may occur, and related APIs. Document dependencies (such as permissions) needed to call it and the behavior when a dependency is missing ("the method throws a SecurityException", "the method returns null"). Use present tense for all descriptions — *Adds a new bird to the ornithology list.* / *Returns a bird.*

Opening formulas:

| Method kind | Start the description with |
| --- | --- |
| Performs an operation and returns data | A verb describing the operation: "Adds a new bird to the ornithology list and returns the ID of the new entry." |
| Getter returning a boolean | "Checks whether...." |
| Getter returning anything else | "Gets the...." |
| No return value | "Sets the...." (ability/setting), "Updates the...." (property), "Deletes the....", "Registers...." (callback or element for later reference) |
| Callback (usually named starting with "on", such as `onBufferingUpdate`) | "Called by...." — for example, "Called by Android when....". Later in the description: "Subclasses implement this method to...." |
| Convenience method that constructs the class object | "Creates a...." |

### Parameters

- Capitalize the first word; end the sentence or phrase with a period.
- Begin non-boolean parameter descriptions with "The" or "A" if possible: *The ID of the bird you want to get.* / *A description of the bird.*
- Boolean parameter that tells the API to do or not do something: state what the API does if true and if false — *`enableCertificateValidation`: If true, validates the SSL certificate before proceeding. If false, trusts the certificate without validating it.*
- Boolean parameter that declares the already-established state of something: use the format "True if...; false otherwise." — *True if the zoom is set; false otherwise.*
- In this context, do NOT put "true" and "false" in code font or quotation marks (an explicit inversion of the usual boolean code-font rule).
- Parameters with default behavior: explain the behavior for each value or range of values, then state the default using the format *Default:*.

### Return values

Be as brief as possible; put detailed information in the class description. Non-boolean: start with "The..." — *The bird specified by the given ID.* Boolean: "True if...; false otherwise." — *True if the bird is in the sanctuary; false otherwise.*

### Exceptions

If the reference generator automatically inserts the word "Throws", begin with "If...": *If no key is assigned.* Otherwise begin with "Thrown when...": *Thrown when no key is assigned.*

### Deprecations

Tell the user what to use as a replacement, in the first sentence — only the first sentence appears in the summary section and index. If you track the API with version numbers, mention which version it was first deprecated in. Subsequent sentences can explain why. For a deprecated method, tell the reader what to do to make their code work.

Examples: *Deprecated. Use #CameraPose instead.* / *Deprecated. Access this field using the `getField` method.*

## Code samples (code-samples)

- Indent per the relevant code style guide: for most languages, spaces instead of tabs, two spaces per indentation level. Some contexts use four spaces or tabs. Applies to code samples, not to formatting commands.
- Wrap lines at 80 characters; consider a smaller width if readers have a narrow browser window or will print the document.
- Mark code blocks as preformatted text: HTML `pre` element; in Markdown, indent every line of the block by four spaces.
- Indicate omitted code with a comment in the language of the sample — for example, `# Several lines of code are omitted here.` in YAML. Never three dots or the ellipsis character. A block containing an omission must not be click-to-copy.
- In most cases, precede a sample with an introductory sentence or paragraph: end it with a colon if it immediately precedes the sample; end with a period if other material (such as a note paragraph) intervenes, or if the paragraph ends in a sentence not directly related to the sample.
  - Recommended (ending with a period): The following code sample shows how to use the `get` method. For information about other methods, see [link]. [sample]
  - Also recommended: The following code sample shows how to use the `get` method: [sample] For information about other methods, see [link].
  - Not recommended (ending with a colon): The following code sample shows how to use the `get` method. For information about other methods, see [link]: [sample]
- Follow the public Google coding-style guide for the sample's programming language. Some open source projects have overriding style guides — for example, Java code in the Android Open Source Project follows the AOSP Java Code Style for Contributors guide.
