# Command-line syntax and placeholders

Covers slugs: code-syntax, placeholders.

## Command-line syntax (code-syntax)

### Best practices

- Provide an inline link to the command reference, typically in the text that introduces the command or series of steps.
- Use as few optional arguments as possible in non-reference content; rely on the command reference for the complete list of arguments.
- Provide a click-to-copy command example that the reader doesn't need to edit after they copy it: if possible, include only runnable code and placeholder variables. Square brackets (`[]`), pipes (`|`), braces (`{}`), and ellipses (`...`) can break commands if they're not first removed, so avoid optional, mutually exclusive, or repeated arguments in click-to-copy examples (see the click-to-copy section below).

### Format a command

- Mark a block of code such as a lengthy command or a code sample as preformatted: HTML `pre` element; Markdown code fence (```` ``` ````).
- When a line exceeds 80 characters, you can safely add a line break before some characters, such as a single hyphen, double hyphen, underscore, or quotation marks. After the first line, indent each line by four spaces to vertically align each line that follows a line break.
- Each line except the last must end with the command-continuation character; commands without it don't work.
  - Linux or Cloud Shell: a backslash typically preceded with a space (` \`)
  - Windows: a caret preceded with a space (` ^`)
- Format placeholder text as placeholders, and follow the command line with a descriptive list of the placeholders used (see the placeholders section below).
- When documenting a command-line option or argument, use end punctuation for complete sentences; don't use end punctuation for single words or noun phrases, unless there is a mix of sentences and noun phrases.
- When documenting a `bash` or `sh` command, follow the quotation-mark style in Google's shell style guide.

### Command prompt

- If instructions show multiple lines of input in one block, start each input line with the prompt symbol. If you don't want users to copy the prompt symbol, you might be able to turn off text selection for the symbol—for example, by using CSS.
- Don't show the current directory path before the prompt, even if part of the instruction includes changing directories. However, if the overall context of the command interface changes—such as from the local machine to a remote machine—add an additional prompt indicator for the new context.
- For a one-line command, the prompt (`$`) is optional; but if the document includes both multi-line and one-line commands, use the prompt on all commands for consistency.
- If instructions include a combination of input and output lines, use separate code blocks for input and output.

Recommended (context change, local to remote):

```
$ adb shell
shell@ $ screencap /sdcard/screen.png
shell@ $ exit
$ adb pull /sdcard/screen.png
```

Recommended (separate input and output blocks):

```
$ cat ~/.ssh/my-ssh-key.pub
```

The output is similar to the following:

```
ssh-rsa KEY_VALUE USERNAME
```

### Argument notation

**Optional arguments**: use square brackets around an argument to indicate that it's optional. If there's more than one optional argument, enclose each item in its own set of square brackets. Here `GROUP` is required; `GLOBAL_FLAG` and `FILENAME` are optional:

```
gcloud dns GROUP [GLOBAL_FLAG] [FILENAME]
```

**Mutually exclusive arguments**: use curly braces to indicate that the reader must choose one—and only one—of the items inside the braces, separated by a pipe (`|`). There can be more than two choices.

```
{FILE_1|FILE_2}
```

A compound example—left of the pipe (cloud repository source), `--source=CLOUD_SOURCE --source-url=SOURCE_URL` is required; right of the pipe (local directory), `--bucket=BUCKET` is required and `--source=LOCAL_SOURCE` is optional per its square brackets:

```
{--source=CLOUD_SOURCE --source-url=SOURCE_URL | --bucket=BUCKET [--source=LOCAL_SOURCE]}
```

**Arguments that can repeat**: use three dots and no spaces (`...`) to indicate that the reader can specify multiple values for the argument:

```
gcloud dns GROUP [GLOBAL_FLAG ...]
```

Avoid all three notations in click-to-copy code examples.

### Optional arguments in click-to-copy commands

Square brackets, curly braces, pipes, and ellipses can break commands if the reader doesn't remove them. Avoid these argument types in click-to-copy commands; instead, choose one of the following four approaches:

1. **Remove the optional arguments.** Use only the necessary arguments for the most common use case; always provide a link to the command reference where readers can find the full list of options.

   Recommended: To get an aggregate list of all virtual machine (VM) instances in all zones for a project, use the `gcloud compute instances list` command:

   ```
   gcloud compute instances list
   ```

   If you want to narrow the list of VMs to a specific zone, use the previous command with the `--zones` flag.

2. **Use separate code blocks for each option.**

   Recommended: To create a bootable Compute Engine image, use the `gcloud compute images import` command:

   ```
   gcloud compute images import IMAGE_NAME \
       --source-file=SOURCE_FILE
   ```

   If you're importing an image with an existing license, specify the `--byol` flag:

   ```
   gcloud compute images import IMAGE_NAME \
       --source-file=SOURCE_FILE \
       --byol
   ```

3. **Document optional arguments in separate tasks** (separate sections). For example, an "Import a bootable virtual disk" section with:

   ```
   gcloud compute images import IMAGE_NAME \
       --source-file=SOURCE_FILE
   ```

   and an "Import a non-bootable virtual disk" section: If your virtual disk doesn't have a bootable operating system installed on it, include the `--data-disk` flag:

   ```
   gcloud compute images import IMAGE_NAME \
       --source-file=SOURCE_FILE \
       --data-disk
   ```

4. **Let the reader know that the command contains optional arguments.** If you must include special characters, indicate that fact when you introduce the command.

   Recommended: ...use the `gcloud compute instance-groups managed create-instance` command with one or multiple `--stateful-disk` flags. In the following example, you optionally specify the `auto-delete` subflag to keep or discard each disk when the VM is permanently deleted:

   ```
   gcloud compute instance-groups managed create-instance NAME \
       --instance=VM_NAME \
       --stateful-disk=device-name=DEVICE_NAME,source=DISK[,auto-delete=DELETE_RULE]
   ```

### Output from commands

- You don't have to show output for every command. Add output only if it adds value—for example, if the reader needs to copy a value from the output or verify a value in it.
- Separate the command from the output with one of these introductory phrases:
  - Recommended: The output is similar to the following:
  - Recommended: The output is the following:
  - To explicitly call out something about the output, customize the phrase. Recommended: The output is similar to the following, in which the `IP` column shows the IP address for each resource:
- To indicate that one or more lines of output are omitted, use three dots and no spaces (`...`) on a separate line. Do not use the ellipsis character (…). For example:

```
Reading file status
Upload done, resetting board...
...
Wakeup reason: 0
```

### Command-line terminology

- Linux commands can be complicated: describe what the entire command does rather than what its individual elements are called, unless the reader must know the name of the command-line element. Linux commands use *options*, *parameters*, *arguments*, metacharacters (globbing), pipes, and redirection symbols.
- **[Cloud]** gcloud commands: the `gcloud` CLI's syntax distinguishes between a *command* and a *command group*, but in docs, command-line contents are generally referred to as commands. A *flag* is a Google Cloud-specific term for any element other than the command or group name itself; a command or flag might also take an *argument*. *Option* is often used as a catchall term to avoid miring the reader in specialized nomenclature. Avoid mapping gcloud nomenclature onto Linux commands.

### Linux signals

Use each signal's canonical verb. These normally discouraged terms are recommended *only* in the context of process control.

| Signal | Verb | Do not substitute |
| --- | --- | --- |
| `SIGKILL` | kill | cancel, end, exit, quit, stop, terminate |
| `SIGTERM` | terminate | cancel, end, exit, quit, stop |
| `SIGQUIT` | quit | cancel, end, exit, quit, stop |
| `SIGINT` | interrupt | suspend, end, exit, pause, terminate |
| `SIGPAUSE` | pause, or sleep | cancel, interrupt |
| `SIGSUSPEND` | suspend | pause, exit |
| `SIGSTOP` | stop | cancel, end, exit, interrupt, quit, terminate |

## Placeholders (placeholders)

Placeholders in sample code and commands represent values that the reader must replace; placeholders in example output can also represent other values that vary (the reader isn't expected to set those). In general, a placeholder has a descriptive name as a default value.

### Naming

- Don't use a single *x* or a series of *x*'s as placeholders; use a more informative placeholder. Exception: in some contexts (such as HTTP status codes), a series of *x*'s is the standard, so it's OK to use (for example) *xx* there.
- Use uppercase characters with underscore delimiters.
  - Recommended: `API_NAME`, `METHOD_NAME`
  - Not recommended: `API-name`, `API_name`, `API name`, `api_name`, `api-name`, `apiName`
- If the context makes uppercase with underscores a bad idea, use something else that makes sense, but be internally consistent.
- Don't include possessive adjectives in placeholders.

### Placeholders in inline text

- HTML, code or command placeholder: `<code><var>PLACEHOLDER_NAME</var></code>`
- HTML, placeholder that does not represent a code sample or command: `<var>PLACEHOLDER_NAME</var>` (no `code` element)
- Markdown: wrap in backticks with an asterisk before the first backtick and after the second one: `` *`PLACEHOLDER_NAME`* ``

### Placeholders in code blocks

- HTML: wrap the code block in a `pre` element and tag placeholders with `var` elements:

  ```
  <pre>
  gcloud compute forwarding-rules create <var>FORWARDING_RULE_NAME</var> \
      --global | --region=<var>REGION</var> \
      --load-balancing-scheme=<var>LOAD_BALANCING_SCHEME</var> \
      --network=<var>NETWORK</var> \
      ...
  </pre>
  ```

- Markdown: wrap the code block in a code fence. Inside a code fence, you can't apply formatting like bold or italic.

### Explain placeholders

Explain each placeholder the first time you use it. Don't repeat the explanation unless doing so benefits the reader—for example: the document is lengthy; you've introduced several other placeholders in a long procedure; or the document isn't intended to be read from beginning to end.

**Single placeholder** — follow the command with: Replace PLACEHOLDER with a description of what the placeholder represents.

Recommended:

1. Stream the build logs to the Google Cloud console:

   ```
   gcloud builds log --stream=BUILD_ID
   ```

   Replace `BUILD_ID` with the ID of the `WORKING` build that you copied in the preceding step.

**Two or more placeholders** — follow the command line with a descriptive list of the placeholders. Explain what each placeholder represents even if the value is intuitive to you.

- Introduce the list with *Replace the following:*
- List the placeholders in the order in which they appear in the command line.
- Tag each placeholder with `code` and `var` elements, followed by a colon and a description that starts with a lowercase letter: `<li><code><var>INSTANCE_NAME</var></code>: description</li>`. For non-code samples, remove the `code` elements.
- If the description contains an example, introduce it with an em dash or *such as*: `<li><code><var>INSTANCE_NAME</var></code>: description&mdash;for example,...</li>` or `<li><code><var>INSTANCE_NAME</var></code>: description, such as...</li>`

Recommended:

1. Set the maximum concurrency target for a new reservation:

   ```
   bq mk \
       --project_id=ADMIN_PROJECT_ID \
       --location=LOCATION \
       --target_job_concurrency=CONCURRENCY \
       --reservation \
       RESERVATION_NAME
   ```

   Replace the following:
   - `ADMIN_PROJECT_ID`: the project that owns the reservation
   - `LOCATION`: the location of the reservation
   - `CONCURRENCY`: the maximum concurrency target
   - `RESERVATION_NAME`: the name of the reservation

**Placeholders in output** — explain any placeholders that appear in sample output:

- Use `var` elements to identify the placeholder text in the output.
- Follow the example output with a list of the placeholders used, introduced with *This output includes the following values:*
- List the placeholders in the order in which they appear in the example.
- Tag each placeholder with a `var` element, followed by a colon and a description that starts with a lowercase letter; introduce embedded examples with an em dash or *such as* (same `<li>` formats as above).

Example list (following sample output introduced with "The output is similar to the following:"):

This output includes the following values:

- `PROJECT_ID`: the project ID for the project that the image was imported into
- `OPERATION_ID`: the ID of the import operation
- `BUILD_ID`: the ID of the build for the import operation
- `IMAGE_NAME`: the name of the image to be imported
- `SOURCE_FILE`: the URI for the image in Cloud Storage—for example, `gs://my-bucket/my-image.vmdk`
- `PROJECT_NUMBER`: the number for the import project
