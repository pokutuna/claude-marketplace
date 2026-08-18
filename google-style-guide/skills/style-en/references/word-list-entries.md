# Word list: selected entries

Consult this while writing or reviewing developer documentation: selected word-list entries, severity wording preserved; words not listed here must be checked on the origin word-list page (see `word-list-principles.md` for how to read entries).

## UI interaction and elements {#ui}

| Term | Guidance |
|---|---|
| click | Use for mouse targets (buttons, links, list items, radio buttons). Don't use *click on*. Hyphenate *right-click*, *left-click*, *double-click*. OK: *click to expand*; *click in* a region needing focus (not a control or link). [Android] Don't use; use *tap*. |
| click here | Don't use; avoid vague link text. |
| tap | Use instead of *click* on touch devices, and instead of *touch*. *touch & hold* (not *touch and hold*) is OK. Mechanical buttons: *press*. [Android] Use for on-screen and soft (capacitive) buttons. |
| press | Use for keys, key combinations, and mechanical buttons. On-screen and soft (capacitive) buttons: *tap*. |
| enter; type | Use *enter* for entering text (typing isn't the only way). Use *type* when typing matters; if it's important to not press Enter, say so. |
| check | Don't use for marking a checkbox. Instead, use *select*. |
| uncheck; deselect; unselect | Don't use for clearing a checkbox — use *clear*. *Deselect* is OK for non-checkbox UI elements; *unselect*: don't use at all. |
| select; clear | Checkbox pair: *select* to mark, *clear* to remove the check mark. *Select* also for choosing among options and selecting text. |
| drag | Use *drag*, not *click and drag*, not *drag and drop*. OK to use *drag-and-drop* as an adjective. |
| hover | Don't use. Use *hold the pointer over* (waiting for the UI to react / duration matters); *point to* is more common. |
| drop-down | Usually omit: just *list* or *menu*; add *drop-down* only if omission causes ambiguity. Don't use as a standalone noun. |
| checkbox | Not *check box*. |
| dialog | The UI element; *dialogue* only for verbal interaction between people. |
| grayed-out, gray out | Don't use. Instead, use *unavailable*. |
| display (verb) | Transitive only: the area *appears* or *is displayed*, never "the area displays". OK with an object: "the area displays the image". |
| text box, textbox | Don't use. Instead, use *box*. [Google Cloud] [Google Workspace] Use *field* instead of *box*. |

## Modal verbs and precision {#precision}

| Term | Guidance |
|---|---|
| since | If you mean *because*, use *because*. *Since* is ambiguous; it can refer to the passage of time. |
| while | Don't use to indicate a contrast; use a more precise term such as *although*. OK for a period of time. |
| once | If you mean *after*, use *after*. |
| may | Reserve for official policy or legal considerations. Possibility → *can* or *might*; permission → *can*. |
| might | Use for possibility or an uncertain outcome. |
| can | Use for permission or ability, optional actions, and possible outcomes. |
| must | Use for a required action or state; *you need* also conveys a requirement. |
| should | Generally avoid — ambiguous by definition. State the requirement (*must*) or option (*can*). |
| will; would | Avoid *will* (present tense; applies equally to *would*). Use *can* where possible. |
| comprise | Don't use. Use *consist of*, *contain*, or *include*. |
| deprecate | Means to recommend against use (typically warning of coming unavailability). Don't use *deprecated* to mean *removed*, *deleted*, *shut down*, or *turned down*. |
| impact | Use only as a noun. Instead of "has an impact", use the verb *affect*. |
| execute | When the meaning is the same, use the simpler word *run*. Use a more precise term if your context needs it. |
| enable | For making something feasible, use *lets you* ("The API lets you detect..."), not "enables/allows you to". For turning on a feature, use *enable* or *turn on* consistently. OK when not referring to a person. [Google Workspace] If possible, use *turn on* or *on*; for a UI element's state, use *available*. |
| allows you to | Don't use. Instead, use *lets you*. |
| disable | Don't use for something broken. For user actions or UI state, use a precise term consistently: *inactive*, *unavailable*, *deactivate*, *turn off*, or *deselect*. |
| like | OK for both comparisons (*similar to*) and introducing examples (*such as*). *Like*/*such as*/*include* introduce non-exhaustive lists, so combining them with *etc.* is redundant. |
| user | Only for users of the software your reader is developing. Address the reader as *you*. |
| we | Don't use *we* (or *our*, *us*) for the reader's actions; use *you*. OK for the authoring organization when the antecedent is clear. |
| please | Don't use when explaining how to use a product (no *please note*). Only when asking permission or forgiveness — the request benefits you, inconveniences the reader, or suggests a product issue. |
| simple, simply; easy, easily; quick, quickly | What might be simple/easy/quick for you might not be for others. Try eliminating the word. |
| just | Avoid; usually filler you can delete. If unclear without it, use *only*, *instead*, *previously*, or rephrase. OK for conveying that one approach is simpler (instead of *simply*). |
| in order to | Avoid; use *to*. Keep *in order to* when needed for clarity or readability. |
| data | Singular mass noun: *the data is*, *less data* (not *are*, *fewer*). |
| emoji | Use *emoji* for both singular and plural. |
| appendix; index | Plurals *appendixes*, *indexes* — not *-ices* (exception: domain-specific mathematical/financial *indices*). |

## Latin abbreviations and connectors {#abbreviations}

| Term | Guidance |
|---|---|
| e.g. | Don't use. Use *for example* or *such as*. |
| i.e. | Don't use. Use *that is*. |
| etc.; and so on | Avoid *etc.*, *and so forth*, and *and so on* wherever possible (prefer "such as X or Y" / "including X"). If you really need one, use *etc.* — always with its period, even before a comma. |
| and/or | Don't use unless space is limited, such as in a table. |
| vs. | Don't abbreviate; use *versus*. |
| via | Don't use. |
| per | Use for rates (*requests per day*). Avoid otherwise: *for each Pod*, *according to the style guide* — not *per Pod*, *per the style guide*, *as per your request*. |

## Timeless documentation {#timeless}

| Term | Guidance |
|---|---|
| currently; presently, at present; as of this writing | Avoid — implied, and can leak strategy or imply change. |
| now | Avoid for product features (implied). OK for an explicit past-vs-present comparison. |
| soon; eventually; future, in the future | Avoid in timeless documentation — becomes outdated and can leak roadmap. |
| does not yet | Avoid — becomes outdated; write "doesn't support". |
| latest | Avoid; if you must, give a reference point (version number or release date). |
| new, newer | Avoid; if you must, anchor with a version/date. For versions use *later* [Android: *higher*] + version number, not *newer*. |
| old, older | Don't use for a previous version — use *earlier* [Android: *lower*] plus a version number. |

## Positions and versions {#positions}

| Term | Guidance |
|---|---|
| above; below | Don't use for version ranges (use *later*/*earlier*), document position (use *earlier*/*preceding*, *later*/*following*), or UI position (write non-directional instructions). OK non-directionally (hierarchy; set phrases like *below average*, *below zero*). |
| earlier; later | Use for version ranges: "version 2.2 or earlier/later" — not *lower*/*higher*, not "2.2+". [Android] Inverted: use *lower*/*higher*, not *earlier*/*later*. Document position: *earlier*/*preceding*, *later*/*following*. The highest version number might not be the latest release. |
| higher; lower | Don't use for version ranges (use *later*/*earlier*), document position, or UI position. [Android] DO use *higher*/*lower* for version ranges. |

## Inclusive and figurative language {#inclusive}

| Term | Guidance |
|---|---|
| blacklist, whitelist, graylist (all spellings; -listed, -listing) | Don't use. Nouns: *denylist*/*excludelist*/*blocklist*; *allowlist*/*trustlist*/*safelist*; *provisional list* — there might not actually be a list; be technically accurate. Verbs: don't substitute word-for-word; rewrite the action ("To deny requests from an IP address, add it to the `dos.yaml` file"). Code literals: only in direct reference to the code item, in code font. |
| allowlist, denylist (verb forms) | Don't use as verbs (*allowlisted*, *denylisting*); rewrite to improve clarity. OK as nouns. |
| blackhat, whitehat, grayhat | Don't use. Use precise terms for the violation or compliance: *illegal*, *unethical*, *in violation of rules* / *legal*, *ethical*, *following the rules*. |
| black-box, white-box, gray-box | Avoid for monitoring and testing. Monitoring: *synthetic* / *introspective monitoring*. Testing: *opaque-box* / *clear-box* testing; combinations: describe them (or *translucent-box testing*). |
| master | Use with caution; never in conjunction with *slave*. Where possible use a context-accurate term: *primary*, *main*, *original*, *parent*, *controller*, *leader*, *active*, etc.; *GKE control plane*, *root key* / *primary key* (not *master key*). Code literal: direct reference in code font, then the new term thereafter. |
| slave | Don't use. Use *worker*, *replica*, *secondary*, etc.; as pairs: *primary/secondary*, *primary/replica*, *controller/worker*, *leader/follower*, *active/standby*, etc. Same code-literal rule as *master*. |
| grandfathered; grandfather clause | Don't use. Use an adjective like *legacy* or *exempt*, or a verb like *made an exception*. |
| sanity check | Don't use. Use *quick check*, *confidence check*, *preliminary check*, or *coherence check*. |
| sane | Don't use. Use a word like *valid* or *sensible*. |
| crazy, bonkers, mad, lunatic, insane, loony | Don't use. Use *complicated*, *complex*, *baffling*, *strange*, or *unexpected* — and only for inanimate objects. |
| dumb down | Don't use. Use *simplify* or *remove technical jargon*. |
| cripple | Don't use ("it slowed the server down", not "it crippled the server"). For people, describe the specific impairment (*person with a motor disability*, *wheelchair user*). |
| blind (figurative) | Avoid *blind to* / *blind eye to* (use *ignore*, *unaware of*, *disregard*); *blind writes* (*a write operation without a read operation*); *blind change* (*change without first confirming the value*). For people: *person who is blind*, *screen reader user*, etc. |
| lame; gimp; retarded | Don't use. Use precise, non-figurative language for a deficiency; for slowing, use *slowed*. *Gimp* OK in names of companies, tools, and packages. |
| ghetto | Don't use. Use *clumsy*, *workaround*, or *inelegant* for code that isn't production-ready. |
| gypsy | Don't use. For the people, use *Romani*, *Roma*, or *Traveller* as appropriate; replace metaphorical uses with precise phrases. |
| guys, you guys | Use non-gendered language for groups, such as *everyone* or *folks*. |
| he, him, his; she, her, hers; gender-neutral he | Don't use a gendered pronoun except for a specific individual of known gender. Use singular *they*/*their*. Never *he/she*, *(s)he*, or other punctuational approaches. |
| man hours; manpower; manned; manmade | Avoid gendered terms: *person hours*; *staff*, *workforce*; *staffed*, *crewed*; *artificial*, *manufactured*, *synthetic*. |
| man-in-the-middle (MITM) | Avoid gendered terms; use *on-path attacker* or *person-in-the-middle (PITM)*. |
| female adapter; male adapter | Don't use. Use a genderless word: *socket* / *plug*. |
| first class, first-class citizen | Don't use. Use a context-appropriate term such as *higher-order*, *anonymous*, or *nested*, or describe the entity's actual capabilities. |
| kill | Avoid when possible. Use *stop*, *exit*, *cancel*, or *end*. Exception: documenting command-line syntax for Linux signals. |
| nuke | Don't use. Use *remove* or *attack* (e.g. *denial-of-service attack*). |
| hang, hung | Don't use for a system that is not responding. Use *stop responding* or *not responding*. |
| war room | Don't use. Use a precise term: *rapid response team*, *situation room*, *incident-management team*, etc. |
| blast radius | Don't use. Use *affected area* or *spatial impact*. |
| final solution | Don't use. Use *solution* standalone, or *definitive*, *optimal*, *best*, or *last solution*. |
| demilitarized zone (DMZ) | Don't use. Use a more precise term like *perimeter network*. |
| STONITH, STOMITH | Avoid graphic or metaphorical language; explain the feature, such as *fence failed nodes*. |

## Spelling and compound forms {#orthography}

| Term | Guidance |
|---|---|
| login (noun/adj), log in (verb) | Verb is two words; *sign in* is generally better. If a tool uses *log in*, match the tool. |
| sign-in (noun/adj), sign in (verb) | Not *log in* or *signin*. |
| sign into | Don't use. Instead, use *sign in to*. |
| setup / set up; startup / start up; timeout / time out | Noun (or adjective) closed, verb open: *setup*/*set up*, *startup*/*start up*, *timeout*/*time out*. |
| plugin (noun), plug-in (adjective), plug in (verb) | Three distinct forms. |
| backend; frontend | Not *back-end*/*back end* or *front-end*/*front end*. |
| filename; hostname; whitespace | Not *file name*, *host name*, *white space*. |
| file system | Not *filesystem* (despite *filename*). |
| sub-command | Not *subcommand*. |
| email | Not *e-mail*. Don't use as a verb; use a specific verb: *send email*. |
| internet | Lowercase except at the beginning of a sentence, heading, or list item. |
| curl | Not *cURL*. |

## Android-only entries {#android}

| Term | Guidance |
|---|---|
| action bar | Don't use; use *app bar* (formerly *action bar*). |
| admin; administrator | Generally write out *administrator* unless it's a UI label. [Android] Don't use *administrator*; use *admin*. |
| all apps screen | Lowercase except at the beginning of a sentence, heading, or list item. |
| home screen | Two words; not *homescreen* or *home-screen*. |
| lock screen | Two words; not *lockscreen* or *lock-screen*. |
| long press | Don't use; use *touch & hold* (not *touch and hold*). |
| tap & hold, tap and hold | Don't use; use *touch & hold*. |
| touch | Don't use; use *tap*. However, *touch & hold* is OK. |
| notification drawer | Don't hyphenate; lowercase except at the beginning of a sentence, heading, or list item. |
| overview screen | Don't use; use *recents screen*. |

## Google Cloud-only entries {#cloud}

| Term | Guidance |
|---|---|
| project | Use *Google Cloud project* on first mention and wherever the kind of project might be ambiguous. |
| quota | Where possible prefer a specific term such as *usage limit* — but in Google Cloud documentation the standard term is *quota*, so use it. |

(*text box* → *field* [Cloud/Workspace] and *enable* → *turn on* [Workspace] appear in the UI and Precision sections.)
