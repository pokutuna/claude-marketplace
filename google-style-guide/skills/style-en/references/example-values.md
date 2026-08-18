# Example values and filenames

Covers: examples, filenames, phone-numbers.

## Example domains and names (examples)

Never use real domain names, email addresses, or people's names in examples. Don't reveal personally identifiable information (PII) — domain names, email addresses, phone numbers, people's names, project names, or credit card numbers. Use imaginary (fictitious) values or placeholders like `USER_ID` or `EMAIL_ADDRESS`.

### Domain names

For a generic domain, use example.com, example.org, or example.net (reserved by IANA for documentation). Alternatively, use any of these domains, which Google owns specifically for documentation:

- altostrat.com
- examplepetstore.com
- example-pet-store.com
- myownpersonaldomain.com
- my-own-personal-domain.com
- cymbalgroup.com

For an internationalized domain name, use one of the IDN Test TLDs, copying from the "URL of the test site" column. Hostnames with non-ASCII characters are encoded using Punycode: for example, an Arabic test hostname is encoded as `xn--kgbechtv`.

### Email addresses

Build generic email addresses from an approved example domain plus an approved person name — for example, dana@example.com. Generic addresses like support@example.net are OK. Don't use person names, product names, or made-up names in email addresses outside these lists.

### Person names

Draw example given names only from this list:

Alex, Amal, Ariel, Bola, Charlie, Cruz, Dana, Dani, Hao, Ira, Izumi, Jie, Kai, Kalani, Kim, Kiran, Lee, Lucian, Luka, Mahan, Noam, Nur, Quinn, Raha, Rosario, Sasha, Tal, Taylor, Tristan, Yuri

For surnames, use an initial after the given name — for example, Quinn N. or Dana A.

Make example people inclusive:

- Include a variety of people (jobs, cultural contexts, backgrounds).
- Use gender-neutral singular *they*, *their*, *theirs* whenever possible; avoid specifying gender unless integral to the information; avoid examples that depend on a gender binary. If an example requires specifying gender, check that chosen names don't carry a conflicting gender connotation in a given language or culture.
- Avoid reinforcing stereotypes: job roles/levels (such as executive) disproportionately assigned gendered personas, or roles (such as developer or engineer) disproportionately assigned ethnic personas.

Use names from the approved list in most documentation. Exception: some security documentation uses the Alice and Bob cast of characters — use those characters only when documenting a technical specification that uses them, and then use only names from that cast.

### Company names

Use Example Organization. To differentiate two fictional companies, add a description: Enterprise Example Organization, Startup Example Organization.

### Phone numbers

Use a US number in the range 800-555-0100 through 800-555-0199 (reserved for examples and fiction). Never use a real phone number in examples.

### IP addresses

IPv4 (RFC 5737, reserved for documentation):

- `192.0.2.0` through `192.0.2.255`
- `198.51.100.0` through `198.51.100.255`
- `203.0.113.0` through `203.0.113.255`

IPv4 ranges: `192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`

IPv6 (RFC 3849 range), example addresses:

- `2001:db8::`
- `2001:db8:ffff:ffff:ffff:ffff:ffff:ffff`
- `2001:db8:1:1:1:1:1:1`
- `2001:db8:2:2:2:2:2:2`
- `2001:db8:3:3:3:3:3:3`
- `2001:db8:4:4:4:4:4:4`

IPv6 range: `2001:db8::/32`

### Street addresses

Avoid real street addresses. Use one of these fictional addresses:

- 1800 Amphibious Blvd., Mountain View, CA 94045
- Avenida da Pastelaria, 1903, Lisbon, 1229-076
- 8 Rue du Nom Fictif, 341 Paris

### Project names

Create names that are meaningful or descriptive and applicable to the reader's environment. Don't use unclear components like `foo`, `bar`, and `baz`. When necessary, use an appended numbering scheme: `staging`, `frontend-development`, `backend-development`, `production-1`, `production-2`.

### Service account IDs

For a unique service account ID, use the numeric ID `123456789012345678901`.

## Filenames (filenames)

### Naming rules

- Make file and directory names lowercase (occasional exceptions for consistency) — most Unix-style systems are case sensitive, so `Impersonate-Service-Accounts.html` and `impersonate-service-accounts.html` are distinct files.
- Separate words with hyphens, not underscores (`query-data.html`) — search engines read hyphens as spaces; underscores hurt SEO. Exception: in a directory where everything already uses underscores and renaming isn't feasible, use underscores to stay consistent (adding `lesson_4.jd` next to `lesson_1.jd` … `lesson_3.jd`); in all other situations use hyphens.
- Use only standard ASCII alphanumeric characters (so not `avoiding-clichés.jd`).
- Don't use generic page names such as `document1.html`.
- Other exceptions: inconsistency is OK when unavoidable — for example, tool-generated reference docs, or names following the product's or API's own conventions.

### Referring to files

When referring to a specific file:

- Use code font.
- Include the word *file* after the filename.
- Keep the exact spelling even if it doesn't follow the naming guidelines.
- If a sample of the file appears on the page, precede it with an introductory sentence or paragraph that includes the filename. Recommended: "In the following `build.sh` file, modify the default values for all parameters:"

Don't use file types as verbs. Recommended: "Extract a zip file." Not: "Unzip a zip file."

### File types

Use the formal file type name, not the extension (often all caps — many are acronyms/initialisms). Recommended: a PNG file, a Bash file. Not: a `.png` file, an `.sh` file.

| Extension | File type name |
| --- | --- |
| `.adoc` | AsciiDoc file |
| `.csv` | CSV file |
| `.exe` | executable file |
| `.gif` | GIF file |
| `.img` | disk image file |
| `.ipynb` | IPYNB file |
| `.jar` | JAR file |
| `.jpg`, `.jpeg` | JPEG file |
| `.json` | JSON file |
| `.md` | Markdown file |
| `.pdf` | PDF file |
| `.png` | PNG file |
| `.ps` | PowerShell file |
| `.py` | Python file |
| `.sh` | Bash file |
| `.sql` | SQL file |
| `.svg` | SVG file |
| `.tar` | tar file |
| `.tf` | Terraform file |
| `.tiff` | TIFF file |
| `.txt` | text file |
| `.wasm` | Wasm file |
| `.yaml` | YAML file |
| `.zip` | zip file |

## Phone numbers (phone-numbers)

- Example numbers: US range 800-555-0100 through 800-555-0199 only; never a real number.
- Use a nonbreaking hyphen (`&#8209;`) in HTML or Markdown so the number stays on one line: `415&#8209;555&#8209;0132`.
- NANP (US, Canada) real numbers: nonbreaking hyphens separating area code, three-digit exchange code, and four-digit number — 415-555-0132.
- Non-NANP international real numbers: include country and area codes, with a plus sign immediately before the country code (no space; the plus stands in for the country-specific exit code) — +1-415-555-0132.
- Extensions: follow the number with the word *extension*, then the extension number — 415-555-0132, extension 987.
