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
const LIST_LOGBOOK = _lists[7].name();

// Today task IDs for flagging
const _todayTodos = app.lists[LIST_TODAY].toDos();
const _todayIdSet = {};
for (let i = 0; i < _todayTodos.length; i++) {
  _todayIdSet[_todayTodos[i].id()] = true;
}

// ---------------------------------------------------------------------------
// Serialize
// ---------------------------------------------------------------------------

function serializeTask(t) {
  let dueDate = "";
  try {
    const d = t.dueDate();
    if (d) {
      // Format in JST (Asia/Tokyo, UTC+9)
      var y = d.getFullYear();
      var m = ("0" + (d.getMonth() + 1)).slice(-2);
      var day = ("0" + d.getDate()).slice(-2);
      dueDate = y + "-" + m + "-" + day;
    }
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
    dueDate: dueDate,
    tagNames: t.tagNames() || "",
    projectName: projName,
    areaName: areaName,
    isToday: !!_todayIdSet[t.id()],
  };
}

// ---------------------------------------------------------------------------
// Markdown formatters
// ---------------------------------------------------------------------------

function displayName(t) {
  if (t.name) return t.name;
  if (t.notes) {
    var first = t.notes.split("\n")[0];
    var truncated = first.length > 20 ? first.slice(0, 20) + "..." : first;
    return "(note) " + truncated;
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
    project: undefined,
    area: undefined,
    today: false,
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
      case "--project":
        opts.project = argv[++i];
        break;
      case "--area":
        opts.area = argv[++i];
        break;
      case "--today":
        opts.today = true;
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

function cmdToday(opts) {
  const todos = app.lists[LIST_TODAY].toDos();
  const { tasks, total } = listTodos(
    todos,
    opts.includeDone,
    opts.offset,
    opts.limit,
  );
  return formatTaskList("Today", tasks, total, opts.offset, opts.limit);
}

function cmdInbox(opts) {
  const todos = app.lists[LIST_INBOX].toDos();
  const { tasks, total } = listTodos(
    todos,
    opts.includeDone,
    opts.offset,
    opts.limit,
  );
  return formatTaskList("Inbox", tasks, total, opts.offset, opts.limit);
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
    // Fall back to name search
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

function cmdSetToday(taskId, enable) {
  const t = app.toDos.byId(taskId);
  const name = t.name();
  const dest = enable ? LIST_TODAY : LIST_ANYTIME;
  // JXA app.move() doesn't work with Things — use AppleScript via shell
  const shellApp = Application.currentApplication();
  shellApp.includeStandardAdditions = true;
  const escaped = taskId.replace(/"/g, '\\"');
  const escapedDest = dest.replace(/"/g, '\\"');
  shellApp.doShellScript(
    'osascript -e \'tell application "Things3" to move (to do id "' +
      escaped +
      '") to list "' +
      escapedDest +
      "\"'",
  );
  const action = enable ? "moved to Today" : "removed from Today";
  return name + " " + action + ".";
}

function cmdCreate(title, opts) {
  const props = { name: title };
  if (opts.notes) props.notes = opts.notes;
  if (opts.tags) props.tagNames = opts.tags;
  if (opts.due) {
    // Parse as local date (YYYY-MM-DD)
    var parts = opts.due.split("-");
    props.dueDate = new Date(
      parseInt(parts[0], 10),
      parseInt(parts[1], 10) - 1,
      parseInt(parts[2], 10),
    );
  }

  // Determine container: project > area > inbox
  let container = app.lists[LIST_INBOX];
  if (opts.project) container = app.projects[opts.project];
  else if (opts.area) container = app.areas[opts.area];

  const t = app.make({
    new: "toDo",
    withProperties: props,
    at: container,
  });

  // Move to Today if requested
  if (opts.today) {
    const shellApp = Application.currentApplication();
    shellApp.includeStandardAdditions = true;
    const escaped = t.id().replace(/"/g, '\\"');
    const escapedDest = LIST_TODAY.replace(/"/g, '\\"');
    shellApp.doShellScript(
      'osascript -e \'tell application "Things3" to move (to do id "' +
        escaped +
        '") to list "' +
        escapedDest +
        "\"'",
    );
  }

  return "Created: " + title + " [ID: " + t.id() + "]";
}

function cmdUpdate(taskId, opts) {
  const t = app.toDos.byId(taskId);
  if (opts.name !== undefined) t.name = opts.name;
  if (opts.notes !== undefined) t.notes = opts.notes;
  return "Updated task **" + t.name() + "**.";
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
    '  create      <title> [--notes "..."] [--tags "t1, t2"] [--project "..."] [--area "..."] [--today]',
    "  set-today   <task-id> on|off",
    '  update      <task-id> [--name "..."] [--notes "..."]',
  ].join("\n");
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function run(argv) {
  const { cmd, positional, opts } = parseArgs(argv);

  switch (cmd) {
    case "today":
      return cmdToday(opts);
    case "inbox":
      return cmdInbox(opts);
    case "project":
      return cmdProject(positional[0], opts);
    case "area":
      return cmdArea(positional[0], opts);
    case "detail":
      return cmdDetail(positional[0]);
    case "projects":
      return cmdProjects();
    case "set-today": {
      const enable = ["on", "yes", "true", "1"].indexOf(positional[1]) !== -1;
      return cmdSetToday(positional[0], enable);
    }
    case "create":
      return cmdCreate(positional[0], opts);
    case "update":
      return cmdUpdate(positional[0], opts);
    default:
      return usage();
  }
}
