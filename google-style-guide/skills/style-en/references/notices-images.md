# Notices and images

Covers slugs: notices, images.

## Notices (notices)

A notice offsets important or useful information that isn't part of the flow of the text — but readers tend to skip elements outside their focus. If unsure whether something should be a notice, write it first in regular text, then decide.

- Use notices sparingly: multiple notices on a page lose their visual distinctiveness, especially two (or more) in a row. See if you can convey the information another way.
- Where possible, avoid grouping two or more notices (for example, a note with a caution inside it, or several warnings in a row). If grouping seems necessary, reorganize the content instead.

### Notice types (pick by severity)

- **Note**: An ordinary aside or tip. Information that is useful but not critical to the reader. Example: "Generating excessive amounts of traffic to external systems can resemble a denial-of-service attack."
- **Caution**: Tells the reader to proceed carefully. Example: "We don't recommend using a broad `0.0.0.0/0` range that would allow all traffic."
- **Warning**: Stronger than a caution; means "Don't do this" or that the step might be irreversible, such as leading to permanent data loss. If the reader doesn't heed it, they can lose money, lose work, or open themselves to a security breach. Example: "Don't put a password on the command line; doing so is a security risk."
- **Success**: Describes a successful action or an error-free status. Used only in interactive or dynamic content; don't use this notice type in ordinary static pages. Example: "You've successfully deployed an application to GKE."

### When to use a Note

Create a note only when **all** of the following are true:

- The information is *relevant* but not *necessary* to what the reader is doing right now — if the reader skips it, they'll still succeed.
- Interrupting the reader at this point is not an obstacle. For example, the note isn't suggesting an alternative that leads the reader down a different path.
- The information is not part of the flow of what you're writing — it's not just a continuation, a result, or a pointer to additional information.

### When NOT to use a Note

- Don't use notes for cross-references.
- Don't use notes to tell the reader about prerequisites or about steps they should have taken earlier; that information should precede the step.
- Don't make a full procedural step into a note.
- Don't use notes to provide information that's necessary for the reader to succeed.
- Don't use notes for information that's in flow with the preceding text — for example, to state expected results or to include information that simply describes what precedes.

### Presentation

Use whatever visual presentation for notices is standard for your site. If you're writing in HTML and your site doesn't specify what HTML to use, use code similar to:

```
<aside class="note"><b>Note:</b> All VPC networks include firewall
rules.</aside>
```

## Figures and other images (images)

### When to use images

- Use images only when they provide useful visual explanations of information that is otherwise difficult to express with words. For screenshots, be discreet: only capture UIs that are important to the discussion.
- Don't use images of text, code samples, or terminal output. Use actual text.

### Creating and saving images

- Diagrams: use SVG if possible (stays sharp when zoomed); otherwise PNG unless you have a good reason for another format. Never use a transparent background.
- Animations and videos: don't use animated GIF; use a resource-efficient format such as MP4.
- Within a document or doc set, be consistent in screenshot OS and appearance (for example, drop shadows). Crop screenshots to the relevant information.
- No personally identifying information (PII) in screenshots. Hide PII with a solid-color overlay at 100% opacity — never blurs or mosaic effects, which can be reversed. Flatten images exported to layered formats (PDF, TIFF).
- No image maps; provide a list of text references following the image instead.
- Use descriptive filenames.

### Introductory sentences

Introduce most images with a complete sentence — usually ending with a colon if it immediately precedes the image, usually a period if more material (such as a note paragraph) intervenes. Exception: screenshots that immediately follow procedural text describing a UI need no introduction.

Example: "The following diagram shows how you can apply bounded contexts to an existing ecommerce application:"

### Alt text (full spec)

Alt text is a concise description that can replace the image (screen readers, text-only browsers, low bandwidth). It should consider the *context* of the image, not just its content.

- Write short, descriptive alt text in 155 characters or less.
- Exception: if the image presents more useful information than fits in 155 characters, include a brief summary in the `alt` attribute and a more extensive description of the image in the text.
- If the image is decorative (not informative) or only a visual aid for information already expressed in text, provide empty alt text (`alt=""`) so assistive technologies ignore it. Decorative examples: a UI screenshot showing how to fill out fields; icons in the UI; images that just make the page more visually appealing. Guiding rule: replacing every image with its alt text shouldn't change the meaning of the page; if the alt text would be redundant with surrounding text or not useful to visually impaired readers, use the empty tag.
- The `alt` attribute is required on `img` even when its value is an empty string; if you omit it completely, screen readers might read the filename aloud.
- Don't include phrases like *Image of* or *Photo of*.
- Include punctuation — screen readers pause at punctuation.
- Use consistent alt text for repeated instances of an image (controls, status indicators, icons that appear multiple times).
- When possible, avoid all-caps (some screen readers read capital letters individually).
- Introduce diagrams in the text, not in the alt text. Don't use figure captions to replace alt text.
- Use full sentences or a noun phrase.
  - Recommended: `alt="Architecture of an app that's built with Apps Script."`
  - Recommended: `alt="A card message."`

### Figure captions

Figure captions are concise, comprehensive summaries of a figure. Captions and figure numbers are optional. (In HTML, wrap both `figcaption` and `img` in a `figure` element.)

- If you use figure numbers, use the form "\<b>Figure NUMBER.\</b> DESCRIPTION."
  - Recommended: **Figure 1**. Application capabilities are separated into bounded contexts that migrate to services.
  - Recommended: Application capabilities are separated into bounded contexts that migrate to services.
  - Not recommended: Bounded contexts
- Use complete sentences in captions where possible; always use end punctuation.
- When referring to a figure, don't use spatial descriptions such as "the image above." If you used figure numbers, consistently refer to the figure by number, for example "... as shown in figure 1." Don't capitalize *figure* in a reference except at the start of a sentence.
- If you can't use figure numbers, show the figure again when referring to it, for accessibility and user-experience reasons.
- Don't include the figure caption in a sentence referencing the figure.

### Figure descriptions

A figure description conveys in text the information represented by a figure. Any new information should be conveyed through text, never introduced only in a figure or image. Use one when the caption doesn't convey the purpose or complete information of the figure, and use punctuation in it.

### Text in figures

In most cases, avoid embedding explanatory text in screenshot graphics — it hurts accessibility and searchability and increases localization costs. If you must embed text, also provide the same information in an accessible form such as a figure description, keep it brief (avoid complete sentences and punctuation when possible), use sentence case, don't create new abbreviations, and use full trademarked product names. Don't embed figure descriptions or captions in the image — put them in text following the figure. Numbered callouts are OK as aids for writing a figure description, but not for detailed annotations in the image.

### High-resolution images

- Provide high-resolution images via the `srcset` attribute (`1x`/`2x` assets); always still include `src`, pointing to the `1x` image, never the `2x` version.
- The `2x` image must be exactly double the standard image's dimensions (give or take a pixel). Never scale up a `1x` to make the `2x`; if only a `1x` exists, use it alone (scaling down a high-resolution original is fine).
- Browsers that support `srcset` ignore `src`, so list all available resolutions in `srcset`. Set `width` to the CSS pixel size; don't state the height.

### Layout of images on a page

- Don't place or center images manually; use your site's standard CSS image styles. Don't put an `img` element inside a `p` element.
- Don't make images too small — full page width is fine — but in general don't exceed the column width (the `2x` version scaled accordingly). Consider how the image looks when printed.
- Don't link to a figure from within the same page unless the page is very long and the link is quite far from the figure.
