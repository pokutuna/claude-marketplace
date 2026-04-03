#!/usr/bin/env osascript -l JavaScript

// Things 3 JXA bridge — read & update tasks as Markdown

const app = Application("Things3");

// ---------------------------------------------------------------------------
// Resolve locale-dependent built-in list names by index
// ---------------------------------------------------------------------------
const _lists = app.lists();
const LIST_INBOX = _lists[0].name();
const LIST_TODAY = _lists[1].name();
const LIST_ANYTIME = _lists[3].name();

// Lazy-initialized Today ID set (only needed for read commands)
let _todayIdSet = null;
function todayIdSet() {
  if (!_todayIdSet) {
    _todayIdSet = {};
    const todos = app.lists[LIST_TODAY].toDos();
    for (let i = 0; i < todos.length; i++) _todayIdSet[todos[i].id()] = true;
  }
  return _todayIdSet;
}

// ---------------------------------------------------------------------------
// AppleScript helper — JXA move/status/delete don't work directly
// ---------------------------------------------------------------------------
function runAS(script) {
  const sh = Application.currentApplication();
  sh.includeStandardAdditions = true;
  return sh.doShellScript("osascript -e '" + script + "'");
}

function thingsAS(body) {
  return runAS('tell application "Things3" to ' + body);
}

function escapeAS(s) {
  return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function todoRef(taskId) {
  return '(to do id "' + escapeAS(taskId) + '")';
}

// ---------------------------------------------------------------------------
// Serialize
// ---------------------------------------------------------------------------

function formatDate(d) {
  var y = d.getFullYear();
  var m = ("0" + (d.getMonth() + 1)).slice(-2);
  var day = ("0" + d.getDate()).slice(-2);
  return y + "-" + m + "-" + day;
}

function serializeTask(t) {
  let whenDate = "";
  try {
    const w = t.activationDate();
    if (w) whenDate = formatDate(w);
  } catch (e) {}

  let dueDate = "";
  try {
    const d = t.dueDate();
    if (d) dueDate = formatDate(d);
  } catch (e) {}

  let projName = "";
  try {
    projName = t.project().name();
  } catch (e) {}

  let areaName = "";
  try {
    areaName = t.area().name();
  } catch (e) {}

  return {
    id: t.id(),
    name: t.name(),
    status: t.status(),
    notes: t.notes() || "",
    whenDate: whenDate,
    dueDate: dueDate,
    tagNames: t.tagNames() || "",
    projectName: projName,
    areaName: areaName,
    isToday: !!todayIdSet()[t.id()],
  };
}

// ---------------------------------------------------------------------------
// Markdown formatters
// ---------------------------------------------------------------------------

function displayName(t) {
  if (t.name) return t.name;
  if (t.notes) {
    var first = t.notes.split("\n")[0];
    return "(note) " + (first.length > 20 ? first.slice(0, 20) + "..." : first);
  }
  return "(untitled)";
}

function formatTags(tagNames) {
  if (!tagNames) return "";
  return tagNames
    .split(", ")
    .map(function (t) {
      return "#" + t;
    })
    .join(", ");
}

function taskOneline(t) {
  const parts = [];
  if (t.isToday) parts.push("Today");
  if (t.whenDate) parts.push("When: " + t.whenDate);
  if (t.dueDate) parts.push("Due: " + t.dueDate);
  if (t.status === "completed") parts.push("done");
  else if (t.status === "canceled") parts.push("canceled");

  let line = "- " + displayName(t);
  if (parts.length) line += " (" + parts.join(", ") + ")";
  const tags = formatTags(t.tagNames);
  if (tags) line += " " + tags;
  line += " [ID: " + t.id + "]";
  return line;
}

function taskDetail(t) {
  const lines = [displayName(t), ""];
  lines.push("ID: " + t.id);
  lines.push("Status: " + t.status);
  lines.push("Today: " + (t.isToday ? "Yes" : "No"));
  if (t.whenDate) lines.push("When: " + t.whenDate);
  if (t.dueDate) lines.push("Due: " + t.dueDate);
  if (t.tagNames) lines.push("Tags: " + formatTags(t.tagNames));
  if (t.projectName) lines.push("Project: " + t.projectName);
  if (t.areaName) lines.push("Area: " + t.areaName);
  if (t.notes) {
    lines.push("");
    lines.push("Notes:");
    lines.push(t.notes);
  }
  return lines.join("\n");
}

function formatTaskList(title, tasks, total, offset, limit) {
  const lines = ["# " + title, ""];
  if (tasks.length === 0) {
    lines.push("_(no tasks)_");
  } else {
    for (const t of tasks) lines.push(taskOneline(t));
  }
  lines.push("");
  const end = Math.min(offset + limit, total);
  lines.push(
    "_Showing " + (offset + 1) + "–" + end + " of " + total + " tasks_",
  );
  return lines.join("\n");
}

// ---------------------------------------------------------------------------
// List helpers with paging & done filter
// ---------------------------------------------------------------------------

function listTodos(todos, includeDone, offset, limit) {
  let total = 0;
  const results = [];
  let seen = 0;
  for (let i = 0; i < todos.length; i++) {
    const t = todos[i];
    if (!includeDone && t.status() !== "open") continue;
    total++;
    if (seen < offset) {
      seen++;
      continue;
    }
    if (results.length < limit) {
      results.push(serializeTask(t));
      seen++;
    }
  }
  return { tasks: results, total: total };
}

// ---------------------------------------------------------------------------
// Tag helpers
// ---------------------------------------------------------------------------

function parseCsv(str) {
  return str
    .split(",")
    .map(function (s) {
      return s.replace(/^\s+|\s+$/g, "");
    })
    .filter(Boolean);
}

function addTags(todo, tagNamesStr) {
  var existing = {};
  var current = todo.tagNames() || "";
  if (current) {
    var parts = current.split(", ");
    for (var i = 0; i < parts.length; i++) existing[parts[i]] = true;
  }
  var add = parseCsv(tagNamesStr);
  for (var i = 0; i < add.length; i++) existing[add[i]] = true;
  var all = [];
  for (var k in existing) all.push(k);
  todo.tagNames = all.join(", ");
}

function removeTags(todo, tagNamesStr) {
  var current = todo.tagNames() || "";
  if (!current) return;
  var removeSet = {};
  var remove = parseCsv(tagNamesStr);
  for (var i = 0; i < remove.length; i++) removeSet[remove[i]] = true;
  var kept = [];
  var parts = current.split(", ");
  for (var i = 0; i < parts.length; i++) {
    if (!removeSet[parts[i]]) kept.push(parts[i]);
  }
  todo.tagNames = kept.join(", ");
}

// ---------------------------------------------------------------------------
// CLI argument parsing
// ---------------------------------------------------------------------------

function parseArgs(argv) {
  const cmd = argv[0] || "help";
  const opts = {
    includeDone: false,
    offset: 0,
    limit: 30,
    name: undefined,
    notes: undefined,
    tags: undefined,
    addTags: undefined,
    removeTags: undefined,
    project: undefined,
    area: undefined,
    today: undefined,
    when: undefined,
    due: undefined,
  };
  const positional = [];

  for (let i = 1; i < argv.length; i++) {
    switch (argv[i]) {
      case "--done":
        opts.includeDone = true;
        break;
      case "--offset":
        opts.offset = parseInt(argv[++i], 10);
        break;
      case "--limit":
        opts.limit = parseInt(argv[++i], 10);
        break;
      case "--name":
        opts.name = argv[++i];
        break;
      case "--notes":
        opts.notes = argv[++i];
        break;
      case "--tags":
        opts.tags = argv[++i];
        break;
      case "--add-tags":
        opts.addTags = argv[++i];
        break;
      case "--remove-tags":
        opts.removeTags = argv[++i];
        break;
      case "--project":
        opts.project = argv[++i];
        break;
      case "--area":
        opts.area = argv[++i];
        break;
      case "--today":
        opts.today = true;
        break;
      case "--no-today":
        opts.today = false;
        break;
      case "--when":
        opts.when = argv[++i];
        break;
      case "--due":
        opts.due = argv[++i];
        break;
      default:
        positional.push(argv[i]);
    }
  }
  return { cmd, positional, opts };
}

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

function cmdList(listName, title, opts) {
  const todos = app.lists[listName].toDos();
  const { tasks, total } = listTodos(
    todos,
    opts.includeDone,
    opts.offset,
    opts.limit,
  );
  return formatTaskList(title, tasks, total, opts.offset, opts.limit);
}

function cmdProject(name, opts) {
  const todos = app.projects[name].toDos();
  const { tasks, total } = listTodos(
    todos,
    opts.includeDone,
    opts.offset,
    opts.limit,
  );
  return formatTaskList(
    "Project: " + name,
    tasks,
    total,
    opts.offset,
    opts.limit,
  );
}

function cmdArea(name, opts) {
  const todos = app.areas[name].toDos();
  const { tasks, total } = listTodos(
    todos,
    opts.includeDone,
    opts.offset,
    opts.limit,
  );
  return formatTaskList("Area: " + name, tasks, total, opts.offset, opts.limit);
}

function cmdDetail(nameOrId) {
  let t;
  try {
    t = app.toDos.byId(nameOrId);
    t.name(); // test access
  } catch (e) {
    t = app.toDos.whose({ name: nameOrId })[0];
  }
  return taskDetail(serializeTask(t));
}

function cmdProjects() {
  const projects = app.projects();
  const areas = app.areas();
  const lines = ["# Projects & Areas", ""];

  lines.push("## Areas");
  lines.push("");
  if (areas.length === 0) {
    lines.push("_(none)_");
  } else {
    for (let i = 0; i < areas.length; i++) {
      lines.push("- " + areas[i].name());
    }
  }

  lines.push("");
  lines.push("## Projects");
  lines.push("");
  if (projects.length === 0) {
    lines.push("_(none)_");
  } else {
    for (let i = 0; i < projects.length; i++) {
      const p = projects[i];
      let suffix = "";
      if (p.status() !== "open") suffix += " (" + p.status() + ")";
      try {
        suffix += " [" + p.area().name() + "]";
      } catch (e) {}
      lines.push("- " + p.name() + suffix);
    }
  }
  return lines.join("\n");
}

function cmdCreate(title, opts) {
  const props = { name: title };
  if (opts.notes) props.notes = opts.notes;
  if (opts.tags) props.tagNames = opts.tags;
  if (opts.due) {
    var parts = opts.due.split("-");
    props.dueDate = new Date(
      parseInt(parts[0], 10),
      parseInt(parts[1], 10) - 1,
      parseInt(parts[2], 10),
    );
  }

  let container = app.lists[LIST_INBOX];
  if (opts.project) container = app.projects[opts.project];
  else if (opts.area) container = app.areas[opts.area];

  const t = app.make({
    new: "toDo",
    withProperties: props,
    at: container,
  });

  if (opts.when) {
    var wp = opts.when.split("-");
    app.schedule(t, {
      for: new Date(
        parseInt(wp[0], 10),
        parseInt(wp[1], 10) - 1,
        parseInt(wp[2], 10),
      ),
    });
  }

  if (opts.today) {
    thingsAS(
      "move " + todoRef(t.id()) + ' to list "' + escapeAS(LIST_TODAY) + '"',
    );
  }

  return "Created: " + title + " [ID: " + t.id() + "]";
}

function cmdUpdate(taskId, opts) {
  const t = app.toDos.byId(taskId);
  const changes = [];

  if (opts.name !== undefined) {
    t.name = opts.name;
    changes.push("name");
  }
  if (opts.notes !== undefined) {
    t.notes = opts.notes;
    changes.push("notes");
  }
  if (opts.when !== undefined) {
    var wp = opts.when.split("-");
    app.schedule(t, {
      for: new Date(
        parseInt(wp[0], 10),
        parseInt(wp[1], 10) - 1,
        parseInt(wp[2], 10),
      ),
    });
    changes.push("when → " + opts.when);
  }
  if (opts.due !== undefined) {
    var parts = opts.due.split("-");
    t.dueDate = new Date(
      parseInt(parts[0], 10),
      parseInt(parts[1], 10) - 1,
      parseInt(parts[2], 10),
    );
    changes.push("due date");
  }
  if (opts.addTags !== undefined) {
    addTags(t, opts.addTags);
    changes.push("tags (added)");
  }
  if (opts.removeTags !== undefined) {
    removeTags(t, opts.removeTags);
    changes.push("tags (removed)");
  }
  if (opts.tags !== undefined) {
    t.tagNames = opts.tags;
    changes.push("tags");
  }
  if (opts.today === true) {
    thingsAS(
      "move " + todoRef(taskId) + ' to list "' + escapeAS(LIST_TODAY) + '"',
    );
    changes.push("moved to Today");
  } else if (opts.today === false) {
    thingsAS(
      "move " + todoRef(taskId) + ' to list "' + escapeAS(LIST_ANYTIME) + '"',
    );
    changes.push("removed from Today");
  }
  if (opts.area !== undefined) {
    if (opts.area === "none") {
      thingsAS(
        "move " + todoRef(taskId) + ' to list "' + escapeAS(LIST_INBOX) + '"',
      );
      changes.push("moved to Inbox");
    } else {
      thingsAS(
        "move " + todoRef(taskId) + ' to area "' + escapeAS(opts.area) + '"',
      );
      changes.push("area → " + opts.area);
    }
  }
  if (opts.project !== undefined) {
    thingsAS(
      "move " +
        todoRef(taskId) +
        ' to project "' +
        escapeAS(opts.project) +
        '"',
    );
    changes.push("project → " + opts.project);
  }

  if (changes.length === 0) return "No changes specified.";
  return "Updated **" + t.name() + "**: " + changes.join(", ") + ".";
}

function cmdSetStatus(taskId, status) {
  const t = app.toDos.byId(taskId);
  const name = t.name();
  thingsAS("set status of " + todoRef(taskId) + " to " + status);
  const labels = {
    completed: "Completed",
    canceled: "Canceled",
    open: "Reopened",
  };
  return (labels[status] || status) + ": **" + name + "**";
}

function cmdDelete(taskId) {
  const t = app.toDos.byId(taskId);
  const name = t.name();
  thingsAS("delete " + todoRef(taskId));
  return "Deleted: **" + name + "** (moved to Trash)";
}

// ---------------------------------------------------------------------------
// Usage
// ---------------------------------------------------------------------------

function usage() {
  return [
    "Usage: osascript -l JavaScript things.js <command> [options]",
    "",
    "Commands:",
    "  today       [--done] [--offset N] [--limit N]",
    "  inbox       [--done] [--offset N] [--limit N]",
    "  project     <name> [--done] [--offset N] [--limit N]",
    "  area        <name> [--done] [--offset N] [--limit N]",
    "  detail      <name-or-id>",
    "  projects    (list projects and areas)",
    '  create      <title> [--notes "..."] [--tags "t1, t2"] [--when YYYY-MM-DD]',
    '              [--due YYYY-MM-DD] [--project "..."] [--area "..."] [--today]',
    '  update      <task-id> [--name "..."] [--notes "..."] [--when YYYY-MM-DD]',
    '              [--due YYYY-MM-DD] [--tags "..."] [--add-tags "..."] [--remove-tags "..."]',
    '              [--today] [--no-today] [--area "..."|none] [--project "..."]',
    "  complete    <task-id>",
    "  cancel      <task-id>",
    "  reopen      <task-id>",
    "  delete      <task-id>",
  ].join("\n");
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function run(argv) {
  const { cmd, positional, opts } = parseArgs(argv);

  switch (cmd) {
    case "today":
      return cmdList(LIST_TODAY, "Today", opts);
    case "inbox":
      return cmdList(LIST_INBOX, "Inbox", opts);
    case "project":
      return cmdProject(positional[0], opts);
    case "area":
      return cmdArea(positional[0], opts);
    case "detail":
      return cmdDetail(positional[0]);
    case "projects":
      return cmdProjects();
    case "create":
      return cmdCreate(positional[0], opts);
    case "update":
      return cmdUpdate(positional[0], opts);
    case "complete":
      return cmdSetStatus(positional[0], "completed");
    case "cancel":
      return cmdSetStatus(positional[0], "canceled");
    case "reopen":
      return cmdSetStatus(positional[0], "open");
    case "delete":
      return cmdDelete(positional[0]);
    default:
      return usage();
  }
}
