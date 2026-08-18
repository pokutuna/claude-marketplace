# UI elements and interaction

Covers: ui-elements.

## Focus on the task (ui-elements)

When practical, state instructions in terms of what the reader should accomplish, not the widgets and gestures. This clarifies purpose and future-proofs procedures.

- Recommended: Refresh the page.
- Recommended: Expand the **Advanced options** section.

Exceptions — discuss UI elements explicitly when the point of the procedure is to guide the reader through elements on the page, when the UI isn't obvious, or when the audience needs gesture-level detail. Provide the level of detail useful for the intended audience.

- Recommended: Click **Refresh**.
- Recommended: To expand the **Advanced options** section, click the expander arrow.

## Formatting (ui-elements)

Put every UI element name in bold (`b` in HTML, `**` in Markdown): buttons, menus, dialogs, windows, list items, any on-page feature with a visible name. Don't use code font for UI elements — unless the element meets the requirements for code font, in which case use both code font and bold.

Don't bold an official feature or product name, except when it directly refers to an on-page element that uses the name (such as a window title or button name).

- Recommended: In the **New project** window, select the **New activity** checkbox, and then click **Next**.
- Not recommended: In the New Project window, select "New Activity", and then click the "Next" button.

Outside a procedure, provide context locating the element.

- Recommended: The service lets you check the status of all jobs in the **Current jobs** section of the service console.
- Not recommended: The service lets you check the status of all jobs in the **Current jobs** section.

## Capitalization (ui-elements)

Follow the capitalization as it appears on the page. Exceptions: if a label is all uppercase, use sentence case; if multiple referenced labels are inconsistently cased, use sentence case for all of them.

| Case | Recommended | Not recommended |
| --- | --- | --- |
| All-uppercase label | Click **Refresh**. | Click **REFRESH**. |
| Inconsistently cased labels | Click **New project**, and then click **New activity**. | Click **NEW PROJECT**, and then click **New Activity**. |

## Refer to UI elements (ui-elements)

Don't use UI element names as if they were English verbs or nouns.

| Recommended | Not recommended |
| --- | --- |
| In the **Name** field, enter an account name. | **Name** the account. |
| To save the settings, click **Save**. | **Save** the settings. |
| In the **Service account ID** field, enter a name. / For **Service account ID**, enter a name. | Specify a **Service account ID**. |

## Terminology and usage (ui-elements)

In general, focus on the feature and its functionality, not the UI element; name the element when it adds clarity. Both are valid:

- Recommended: Go to **File \> Tools**.
- Recommended: In the **File** menu, click **Tools**.

Don't use slang terms for UI elements, such as *hamburger icon* or *zippy*.

- Not recommended: To expand the **Advanced options** section, click the zippy.

### Windows, pages, dialogs, panes, and sections (ui-elements)

| Term | Meaning | Never call it |
| --- | --- | --- |
| window | the entire application window in a desktop environment; also modular application elements you can open and close | page |
| page | a web page in general; a subpage of a console in particular | window |
| dialog | a smaller window, usually detached from and in front of the main window | pop-up window |
| pane (or panel) | a distinct rectangular region within a larger browser or application window; often tightly coupled to surrounding UI, whereas a window is distinctly separate and can be hidden | window, section, area, column |
| section | a labeled grouping of options and controls, usually within a window, pane, or panel | area, column |

- Recommended: In the **MyApp** window, click **Edit**. / Not recommended: In the **MyApp** page, click **Edit**.
- Recommended: In the Google Cloud console, go to the **Deployments** page. / Not recommended: ...go to the **Deployments** window.
- Recommended: In the **Welcome** dialog, click **OK**. / Not recommended: In the **Welcome** pop-up window, click **OK**.
- Recommended: In the **Create service account** pane, click **New**. / Not recommended: In the **Create service account** section, click **New**.

### Menus (ui-elements)

The *menu bar* (top of window or screen) is a set of *menus* (such as **File** or **Edit**), each a set of related *commands* and/or nested submenus.

- An item in a menu is a *command* — not *choice*, *menu item*, or *option*. Exception: *menu item* is allowed when documenting how to build an interface.
- Refer to a menu as *the **LABEL_NAME** menu*.
- Locate a command in a menu or submenu with a phrase like *In the **File** menu, select **Open**.*
- Don't use *drop-down* as a synonym for *menu*.

#### Angle brackets (ui-elements)

You may abbreviate menu paths with angle brackets (>). Rules:

- Put a nonbreaking space (`&nbsp;`) before each angle bracket.
- Don't bold each menu name separately; enclose the entire sequence in a single bold tag.
- Wrap each angle bracket in a span with an `aria-label` of "and then" (for example, `<span aria-label="and then">></span>`) so screen readers don't read `>` as "greater than."

HTML example:

```
Select <b>View&nbsp;<span aria-label="and then">></span> Tools&nbsp;<span aria-label="and then">></span> Developer Tools</b>.
```

Markdown example:

```
Select **View&nbsp;<span aria-label="and then">></span> Tools <span aria-label="and then">></span> Developer Tools**.
```

This notation applies only to menu items. Never use it to chain different kinds of UI elements.

- Recommended: Select **MyApp \> Preferences**, and then select the **Languages** preference pane.
- Not recommended: Select **MyApp** > **Preferences** > **Languages** > **+** > **CSS**.

### Navigation menu (ui-elements)

A control (usually a pane or window) listing clickable items that go to pages is a *navigation menu* — never *navigation bar*, *navigation pane*, *navigation panel*, or *navigation window*.

### Toolbar (ui-elements)

A *toolbar* is a set of buttons for common user actions; a toolbar button that includes a menu is a *menu button*. Name the toolbar only if the user needs help finding the button.

- Recommended: On the Google Cloud console toolbar, click **Notifications**.
- Recommended: Click **Notifications**.

### Buttons and icons (ui-elements)

Refer to a button by its label. For a button with an icon, write the button's name as shown in the tooltip and add the button icon before the name; if a space is needed between icon and name for readability, use a nonbreaking space. If the icon tooltip is identical to the icon's name, use an empty `alt` attribute.

If unsure of an icon's name, inspect the element in the browser (right-click, then **Inspect** or **Inspect element**) and look for `aria-labelledby`, `aria-label`, `aria-describedby`, `label`, `placeholder`, or `title`. If an icon button has no tooltip, submit a bug report requesting one.

If a UI element name ends with an ellipsis (...), leave out the ellipsis.

Don't use directional language to orient the reader (*above*, *below*, *right-hand side*) — it fails for accessibility and localization. If a UI element is hard to find, provide a screenshot.

- Recommended: Click **Menu**.
- Not recommended: In the left-side panel, click the button with three lines.

For difficult-to-find elements, instead of directional language: use the button icon plus its tooltip name, add context to help the user find it, or use a screenshot.

- Recommended: In the list of services, click **Column display options**.

### Tab (ui-elements)

Refer to a tab as *the **LABEL_NAME** tab*.

- Recommended: Select **Tools \> Options**, and then click the **Edit** tab.

### Text box (ui-elements)

Use *box* and the form *the **LABEL_NAME** box*. Format text the user types in code font (`code` element in HTML; monospace in other markup).

- Recommended: In the **Owner** box, enter your name.
- Recommended: In the **Name** box, enter `wsfc-1`.

**[Cloud]** **[Workspace]** Use *field* instead of *box*.

- Recommended: In the **Instance** field, specify a value less than 64 characters long.

### List box, combo box, and spin box (ui-elements)

- *List box* (offers a list of items): *the **LABEL_NAME** list* or *the **LABEL_NAME** box*, whichever is clearer. Recommended: In the **Item** list, select **Desktop**.
- *Combo box* (text box + list box): *the **LABEL_NAME** box*; for entering a value use *type or select* or *enter*. Recommended: In the **Font** box, type or select the font that you want to use.
- *Spin box* (choose a value by clicking arrows or typing): *the **LABEL_NAME** box*; for entering a value use *enter*. Recommended: In the **Font Size** box, enter a font size.

### Checkbox (ui-elements)

Use *the **LABEL_NAME** checkbox*. Be wary of *check*/*uncheck* (ambiguous); prefer *select* and *clear*. Describe state as *selected* or *not selected*.

- Recommended: Select the **Automatically check for updates** checkbox.
- Recommended: Clear the **Bookmarks** checkbox.
- Recommended: Make sure that the **Bookmarks** checkbox is selected.
- Recommended: Make sure that the **Bookmarks** checkbox isn't selected.

### Radio button (ui-elements)

Refer to a radio button by its label, or refer to the group of buttons by the group's label.

- Recommended: Select **Do not remember passwords**.
- Recommended: For **Startup mode**, select an option.

### Expander arrow (ui-elements)

Avoid referring to expander arrows explicitly; when you must, use *expander arrow* and *expandable section* — never *expando* or *zippy*.

- Recommended: To expand the **Advanced options** section, click the expander arrow.
- Not recommended: To expand the **Advanced options** section, click the zippy.

### Toggle (ui-elements)

Don't use *toggle* as a verb; describe the action the user should take. If the toggle's starting state is unknown, state the target position.

- Recommended: To turn on the setting, click the **Wi-Fi** toggle.
- Recommended: In **Settings**, click the **Magic mode** toggle to the on position.

## Keyboard keys (ui-elements)

- Key the user presses (to cause an action): `kbd` element — `Press <kbd>Control+C</kbd>.` In non-HTML markup, use monospace formatting (how `kbd` renders).
- Key the user types to enter that key's value as text input: `code` element, not `kbd`.

Key naming:

- Letter keys uppercase. Recommended: To save, press Control+S. / Not recommended: To save, press Control+s.
- Use the key's name; if ambiguous, use *the KEY_NAME key*. Recommended: Press Esc. / Recommended: Press the Esc key.
- Spell out modifier key names (Command, Control, Option, Shift); don't use symbols. Combinations: *MODIFIER+KEY_NAME*. Recommended: Press Control+V.
- Combinations with Shift: *MODIFIER+Shift+KEY_NAME*. Recommended: Press Control+Shift+?.
- Spell out confusable characters in shortcuts, such as comma, hyphen, period, and plus.
- Multiple operating systems: put the macOS shortcut in parentheses after the Windows and Linux shortcut. Recommended: To copy, press Control+C (or Command+C on macOS). / Not recommended: To copy, press Ctrl+C (⌘+C).

Say *keyboard shortcut* or *key combination*. Use *press* for pressing a key or combination to cause an action; use *enter* or *type* for typing a key as part of text.

## Prepositions (ui-elements)

| Preposition | UI elements | Examples |
| --- | --- | --- |
| in | dialogs, fields, lists, menus, panes, windows | In the **Alert** dialog, click **OK**. In the **Name** field, enter `wsfc-1`. In the **Item** list, select **Desktop**. In the **File** menu, click **Tools**. In the **Metrics** pane, click **New**. In the **Task** window, click **Start**. |
| on | pages, tabs, toolbars | On the **Create an instance** page, click **Add**. On the **Edit** tab, click **Save**. On the **Dashboard** toolbar, click **Edit**. |

## Verbs in procedures (ui-elements)

Describe on-page actions with these verbs only: click, choose, drag, enable, enter/type, go to, hold the pointer over, press, select, tap, turn on/turn off. Each verb's usage conditions are in its word-list entry (for example, click vs. tap).
