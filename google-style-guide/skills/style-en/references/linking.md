# Linking

Covers: cross-references, headings-targets.

## Cross-references and linking (cross-references)

Cross-references generally link to nonessential information that adds to the reader's understanding. Used well, they help readers navigate; used carelessly, they disrupt.

### Choose links selectively

- Each link creates a decision for the reader (cognitive load) and a chance to leave the page and lose their place. Link to the most relevant page on a site and the most relevant heading on that page; avoid multiple links that do the same job.
- When brief information suffices, provide it on the page instead of linking — for example: define a term, briefly explain a concept, or provide a couple of steps.
- For third-party standards or software, link to good documentation elsewhere rather than thoroughly documenting someone else's standards. But if a few sentences of basic information is all readers need, provide that context on the page and save the trip.

### Avoid duplicate links

Within a given page, don't provide duplicate links to the same destination; provide the link once where it's most useful. A secondary link is OK when:

- You're linking to a particular section of another page.
- Your page is very long and the duplicate links are far apart.
- There are multiple entry points to the document you're linking from — for example, a page with a procedure section and a troubleshooting section might need the same link in both.

### Write descriptive link text

Use short, unique, descriptive phrases that provide context for the linked material and make sense without the surrounding text (screen reader users jump link to link). Rework the sentence if needed to get good link text. Two options:

**Option 1 — exact page title or heading** of the destination:

- Recommended: For more information, see [Load balancing and scaling](https://cloud.google.com/compute/docs/load-balancing-and-autoscaling).

**Option 2 — descriptive phrase**, capitalized as if it's part of the sentence. Help readers quickly judge relevance:

- Place important words at the beginning of the link text.
- Don't use the same link text in the same document for different target pages.
- Keep link text short where possible; don't write lengthy link text such as a sentence or short paragraph.

Examples:

- Recommended: You can use Cloud Scheduler and Cloud Functions to manage [task scheduling on Compute Engine](https://cloud.google.com/blog/products/gcp/reliable-task-scheduling-on-google-compute-engine).
- Not recommended: See [this blog post](https://www.blog.google/products/pixel/pixel-4/).

**Avoid vague link text** — don't use phrases such as *this document*, *this article*, or *click here*:

- Recommended: For more information, see [Make headings into link targets](headings-targets.md).
- Not recommended: Want more? [Click here!](headings-targets.md)

**Avoid URLs as link text** — in general, use the page title or a description of the page instead. **Exception**: in some legal documents (such as some Terms of Service documents), it's okay to use URLs as link text.

- Recommended: `For more information about protocols, see <a href="http://www.w3.org/Protocols/rfc2616/rfc2616.html">HTTP/1.1 RFC</a>.`
- Not recommended: `See the HTTP/1.1 RFC at <a href="http://www.w3.org/Protocols/rfc2616/rfc2616.html">http://www.w3.org/Protocols/rfc2616/rfc2616.html</a>.`

**Include abbreviations in link text** — if the text includes an abbreviation in parentheses, put both the long form and the abbreviation inside the link text: [Google Kubernetes Engine (GKE)], not [Google Kubernetes Engine] (GKE).

### Link to commands and code elements

When linking a command or other code-font element, include the description of the code element in the link text, unless doing so is awkward or redundant.

- Recommended: To create an instance with a custom hostname, run the `gcloud instances create` command with the [`--hostname` flag](https://cloud.google.com/compute/docs/instances/custom-hostname-vm#gcloud).
- Not recommended: To create an instance with a custom hostname, run the `gcloud instances create` command with the [`--hostname`](https://cloud.google.com/compute/docs/instances/custom-hostname-vm#gcloud) flag.
- Recommended: This service supports the [`GET`](), [`HEAD`](), and [`OPTIONS`]() methods.
- Not recommended: This service supports the [`GET` method](), [`HEAD` method](), and [`OPTIONS` method]().

### Write link introductions

When a cross-reference gets its own sentence, introduce it with "For more information, see..." or "For more information about..., see...". Include the "about..." clause when the link text or surrounding context doesn't clearly indicate why you're referring the reader there. Don't use *on* instead of *about*. Use *see* to refer to links and cross-references.

- Recommended: For more information, see [Load balancing and scaling](https://cloud.google.com/compute/docs/load-balancing-and-autoscaling).
- Recommended: For more information about task scheduling, see [Reliable task scheduling on Google Compute Engine](https://cloud.google.com/blog/products/gcp/reliable-task-scheduling-on-google-compute-engine).
- Not recommended: For more information on indexes, see [Manage indexes](https://cloud.google.com/firestore/docs/query-data/indexing).

**Clarify the purpose of a link**: make the surrounding context or the link text itself clearly indicate why you're referring the reader there. Be specific, but don't repeat the link text.

### Explain unexpected link behavior

If a link goes to an unexpected destination or behaves unexpectedly, provide that context:

- **Downloads and emails**: if a link downloads a file or opens an email, make that clear in the link text, and mention the file type.
  - Recommended: For more information, [download the security features PDF](https://www.example.com/security.pdf).
  - Recommended: `<a href="mailto:support@example.com">send email to Technical Support</a>`
- **Sections on the same page**: let the reader know the link stays on the page; use a standard phrase.
  - Recommended: For more information, see the [Write descriptive link text](#descriptive-link-text) section of this document.
- **Sections on another page**: use the same wording and formatting as a regular cross-reference. If the linked section's title is identical to a title on the source page, add context.
  - Recommended: For more information, see [Create a table](https://cloud.google.com/bigtable/docs/managing-tables#create-table).
  - Recommended: For more information, see [Install libraries](#different-page) in "Building new audiences based on existing customer lifetime value."
- **New tabs**: don't force links to open in a new tab or window; let the reader decide. In the rare situation that a link must open in a new tab, tell the reader.
  - Recommended: `<a href="/style/accessibility" target="_blank">Accessible content (opens in a new tab)</a>`
  - Not recommended: `<a href="/style/accessibility" target="_blank">Accessible content</a>`
- **Different domain or server**: don't use an external link icon; if it's important that readers know they're leaving the domain, mention it in the text ("Sometimes OK": For more information, see the Wikipedia page about [OS-level virtualization]).

### Punctuation around link text

Put punctuation immediately before or after a link outside the link tags where possible.

- Recommended: `For more information, see <a href="#Test">Test your code</a>.`
- Not recommended: `For more information, see <a href="#Test">Test your code.</a>`

### Quotation marks and italics

When a cross-reference is a link, don't put the link text in quotation marks.

- Recommended: For more information, see [Meet Android Studio](https://developer.android.com/studio/intro/index.html).
- Not recommended: For more information, see ["Meet Android Studio"](https://developer.android.com/studio/intro/index.html).

In the rare case when a cross-reference isn't a link:

- Unlinked reference to a document section, short work, or part of a series (such as an episode in a web series): use quotation marks.
  - Recommended: For more information, see "Describing system versions" in the following section.
- Unlinked reference to the title of a full-length work (book, movie, web series): use italics.
  - Recommended: ...see *The Chicago Manual of Style*.

### Navigation and sitewide styling

- Avoid linking outside the documentation set from its navigation (such as a table of contents); put the link in a page instead. If you must, make clear the reader will leave the doc set.
- Sitewide CSS: make link text color contrast with regular text, underline link text only (no underlines on non-link text), and make visited links change color using color-blind-friendly changes.

## Headings as link targets (headings-targets)

- Some content management systems auto-generate anchors for headings. Add a *custom* anchor when you want a shorter anchor, when content might be frequently linked to, or when the heading might be revised — auto-generated anchors change with the heading text, breaking existing links.
- Anchor text: lowercase letters, hyphens between words.
- HTML syntax: a `section` element with an `id` attribute (`<section id="introduction-to-everything">` wrapping the heading), or an `a` element with a `name` attribute (inside or immediately before the heading). A bare `<h2 id="...">` is acceptable but not recommended.
- Markdown syntax: append `{: #ID_OF_ANCHOR }` to the end of the heading line (e.g., `## Help conserve habitat for pollinators {: #conserve-habitat }`). The `{: id='...' }` and `{: id="..." }` forms are acceptable.
- Revising a heading with an auto-generated anchor: add a custom anchor that reuses the older ID string (find it by inspecting the published page) so existing links keep working.
- If a heading already has a custom anchor, don't change it — unless it contains a term you want to remove, such as a disrespectful term.
- If you do change an existing custom anchor, check your content management system and update any links that used the old anchor; inbound links with the old anchor still reach the page but not the specific section.
