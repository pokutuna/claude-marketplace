# Numbers, dates and times, units

Covers: numbers, dates-times, units-of-measure, mathematical-notation.

## Numbers (numbers)

### Words vs. numerals

Spell out zero through nine; use numerals for 10 and greater. If it's important to keep the number and its noun on the same line, use a nonbreaking space between them.

- Recommended: four options
- Recommended: The link expires in 24 hours.
- Recommended: 18,000,000 users

**Exceptions — always use numerals, even below 10:**

- Version numbers. Recommended: version 3
- Technical quantities, such as amounts of memory, amounts of disk space, numbers of queries, or usage limits. Recommended: 6 queries per second; 50 Mbps; 128 bits
- Page numbers.
- Chapter numbers, sections, pages, and so on.
- Step numbers (avoid referring to step numbers whenever possible; in edge cases where you have no choice, use the numeral).
- Prices.
- Numbers without units, such as numbers used in mathematical expressions.
- Numbers less than 10 in the same sentence as numbers greater than 9.
  Recommended: The menu contains 15 options but 6 of them are deselected.

Also use numerals for: negative numbers, most fractions, percentages, dimensions, decimal numbers, measurements (Recommended: 8 pixels), and numbers in a range.

Decimals: treat decimal numbers as plural even when less than or equal to 1.0 (Recommended: 1.0 inches). For decimals less than one, place a zero before the decimal point (Recommended: 0.3 inches).

### Sentence-start numbers

Spell out a number that starts a sentence, or rearrange the sentence so the number appears later.

- Recommended: Fifteen directories are created.
- Recommended: In general, avoid sending files larger than 164 MB as attachments.
- Not recommended: 164 MB is generally considered too large a file to send as an attachment.

**Exception:** It's okay, but non-optimal, to begin a sentence with a four-digit year.

### Number followed by a numeral

Spell out a number that is followed by a numeral.

- Recommended: This procedure creates fifteen 100,000-byte files.
- *But*: Recommended: This procedure creates 15 of the 100,000-byte files.

### Indefinite and casual numbers

Words like *millions* or *billions* are fine for approximate numbers; use numerals for precise numbers.

- Recommended: You can specify thousands of combinations.

### Ordinals, Roman numerals, fractions

- Spell out all ordinal numbers in text. Recommended: first, fifth, twelfth, forty-third. Not recommended: 1st, 5th, 12th, 43rd.
- Avoid Roman numerals; Arabic numerals are easier to scan. Roman numerals are OK for sub-steps in numbered procedures.
- Express fractions as decimal numbers when possible. If written as words, connect numerator and denominator with a hyphen unless one is already hyphenated. Recommended: 0.75; one and one-half; two-fifths; five sixty-fourths.

### Percentages

Use numerals and the percent sign (%), with no space between them. Recommended: 40%

**Exception:** If the percentage starts the sentence, spell out both the number and the word *percent*. Recommended: Forty percent of the files

### Ranges of numbers

Use a hyphen with no space on either side. Do not use an en dash (`&ndash;`). Recommended: 2012-2016

### Suspended hyphens

When two or more hyphenated compounds starting with numbers modify the same word, use suspended hyphens.

- Recommended: You can set up the system to scan for new files at one-, two-, or three-hour intervals.

### Commas and decimal points

Standard American formatting: in numbers four or more digits long, use commas to set off groups of three digits, counting leftward from the decimal point. Use a period for the decimal point. No digit-group separators to the right of the decimal point. Even though SI uses a thin space as a digit group separator, use a comma; even though some scientific writing omits commas in four-digit numbers, use a comma for a four-digit number.

- Recommended: The limit is 1,532,784 bytes per day. / Not recommended: The limit is 1532784 bytes per day.
- Recommended: The API supports up to 2,000 vertices. / Not recommended: The API supports up to 2000 vertices.

### Currency

Make clear what country's currency you mean. For US dollars: comma for thousands, period between whole currency and fractions, dollar sign ($) at the beginning, and no punctuation or spaces to the right of the decimal.

- Recommended: The price is $0.006653 per vCPU hour. / Not recommended: The price is $0.006,653 per vCPU hour.
- Recommended: $10,000 in fees is out of reach for many developers. / Not recommended: $10 000 in fees is out of reach for many developers.

### Dimensions and exponents

- Dimensions: numerals joined by a lowercase *x*, no spaces. Recommended: 192x192. Not recommended: 192 x 192.
- Exponents: standard mathematical notation; no space between base and exponent. Recommended: 2<sup>3</sup>
- Accompany numerical concepts with real-world practical implications (for example, if a feature incurs fees, link to a pricing calculator).

## Dates and times (dates-times)

### Times

- Use the 12-hour clock, except if required to use a 24-hour time, such as when documenting features that use 24-hour time. If the UI, a command, or a code sample uses the 24-hour format, use that format throughout the page for consistency.
- Use exact times when possible, but *noon* and *midnight* are OK.
- Hyphenate time ranges, no spaces around the hyphen. Recommended: 5-10 minutes ago.
- Capitalize AM and PM, one space between them and the time. Recommended: 3:45 PM.
- Remove the minutes from round hours. Recommended: 3 PM.

### Time zones

Avoid time zones unless absolutely necessary (such as real events at real times). If needed:

- Tell the reader if the time is local to them—for example, *10 AM your local time*.
- Use the timestamp format as seen in the user interface, if available.
- Spell out the region and include the UTC or GMT label as a parenthetical: US and Canadian Pacific Standard Time (UTC-8); US and Canadian Pacific Daylight Time (UTC-7).
- Don't abbreviate the time zone name.
- If the event's time doesn't change for daylight saving time, use the specific time zone without reference to UTC.

### Dates

Spell out month and weekday names in full; give the full four-digit year. Weekday goes before the month: `DAY_OF_WEEK`, `MONTH` `DAY`, `YEAR`.

- Recommended: January 19, 2017
- Recommended: Tuesday, April 27, 2021

Commas:

- Month + year only: no comma, even mid-sentence. Recommended: She was hired in January 2017. Recommended: The January 2017 release of...
- Full MONTH DAY, YEAR date mid-sentence: comma after the year. Recommended: The January 19, 2017, release of...

Abbreviations: don't abbreviate the day of the week or the month in most cases. When conserving space (heading, table), three-letter abbreviations are OK: capitalize the first letter, no period. Abbreviate the entire date, never mixing written-out and abbreviated forms, and apply consistently throughout the documentation (for example, in all table cells).

- Recommended: Mon, Sep 3, 2018 / Not recommended: Mon, September 3, 2018

Don't express months as numbers—regions order numeric date parts differently, so 04/05/09 means different dates in the UK, the US, and elsewhere.

- Recommended: February 12, 2017
- Not recommended: 02.12.2017 / Not recommended: 12/02/2017

If you must use a numeric-only date, use `YYYY-MM-DD` with hyphens (ISO 8601). If you can choose the date (such as a fictional example), choose a calendar day greater than 12 to differentiate it from the month.

- Recommended: 2017-04-15 / Not recommended: 04/06/2017

Date and time together: date first, then time.

- Recommended: 2017-04-15 at 3 PM
- Recommended: May 4, 2009, at 6 PM

### Seasons

Avoid referring to seasons (hemisphere-dependent); use the month, quarter, or temperature (if relevant).

- Recommended: Changes are released in October of each year. / Not recommended: Changes are released in the Fall of each year.

## Units of measurement (units-of-measure)

### Spaces between number and unit

Put a nonbreaking space (`&nbsp;`) between the number and the unit, in both HTML and Markdown. **Exception:** no space when the unit is money, percent, or degrees of an angle.

Temperature: nonbreaking space between number and degree symbol; no space between the degree symbol (`&deg;`) and the scale (*F* or *C*): 50 °C (`50&nbsp;&deg;C`). Kelvin: no degree symbol, but keep the nonbreaking space: 300 K (`300&nbsp;K`).

When a number and unit combine to modify a noun, don't hyphenate unless the hyphen is needed for clarity.

- Recommended: `200&nbsp;GB disk` (200 GB disk)

### Ranges with units

Repeat the unit for each number in a range. *Unit* includes symbols (like the degree symbol) and abbreviations (like *MB*) but not nouns (like *file*). Use the word *to* between the numbers, not a hyphen—a hyphen can be misinterpreted as a subtraction sign.

### Multiplied units, thousands, currency

- Hyphenate units whose components are multiplied by each other. Recommended: 5 vCPU-hours; 40 person-hours.
- Lowercase *k* for thousands (where appropriate): no space between number and *k*, and add a noun to indicate what the number measures so *k* isn't read as kilobytes (for example, 55k download operations).
- Make the currency unambiguous ($ can mean US dollars, Canadian dollars, Mexican pesos, and others); if there's any possibility of ambiguity, put a currency indicator before the amount. Recommended: US$10

### Rates

Use *per* instead of the division slash (/) when space permits; the slash is OK when space is limited, such as a table with small cells. Shorten *per* to *p* only in well-established rate abbreviations such as *Gbps* or *MBps*.

- Recommended: requests per day / Not recommended: requests/day
- Recommended: Gbps / Not recommended: Gb/s

### Decimal and binary byte units

Use the same system as the technology you're documenting. Don't use *MB* if you mean *MiB*, or *GB* if you mean *GiB*. Decimal: kB (1000 bytes), MB (1000² bytes), GB (1000³ bytes). Binary: KiB (1024 bytes), MiB (1024² bytes), GiB (1024³ bytes).

## Mathematical notation (mathematical-notation)

- Use HTML entities for mathematical symbols instead of keyboard symbols. **Exceptions:** the plus sign (`+`), equals sign (`=`), and division sign (`/`) can use keyboard equivalents.
- Common entities: minus `&minus;`, multiplication `&times;` (or the dot or asterisk operator entity to match the UI; don't use a plain asterisk (`*`) for multiplication in text; the symbol may be omitted, as in *ab*, if unambiguous), `&ne;`, `&lt;`/`&gt;`, `&le;`/`&ge;`, `&asymp;`, `&plusmn;`, `&radic;`, `&sum;`. The full entity table is on the page.
- Operators: use entities (for example `&minus;`, not a hyphen); put `&nbsp;` on both sides of operators within an expression; don't italicize operators. Recommended: *a* − *b*
- Italicize variables. Recommended: *x* ≠ *y*
- Keep short expressions and equations inline, joined with `&nbsp;` so they render on one line; move an expression to its own line if it creates an awkward line break.
- Fractions: same rule as in Numbers. Recommended: 0.02; three-sevenths; three seventy-fourths.
- Exponents/subscripts: use `<sup>`/`<sub>`; no space between base and exponent; never the caret. Recommended: 2<sup>3</sup>. Not recommended: 2^3.
- In running text, prefer notation over words (Recommended: Check whether *a* > *b*)—but use words when notation would be ambiguous, grammatically incorrect, or hard to read (Recommended: The area is calculated by multiplying the length by the width; Not recommended: The area is calculated by multiplying *l* × *w*).
- For complex or multiline equations that HTML entities/tags can't represent clearly, consider diagrams, images, or a dedicated math rendering tool; if using a third-party math tool, follow that tool's formatting guidance.
