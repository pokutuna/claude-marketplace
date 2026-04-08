#!/usr/bin/env bash
set -euo pipefail

# claude-queue — task queue for Claude Code
# Uses git-config format for storage (handles multiline values via \n escaping).
#
# State file:
#   ${XDG_STATE_HOME:-~/.local/state}/claude-queue.conf
#
# Format:
#   [session "<CLAUDE_SESSION_ID>"]
#     item = first task
#     item = second task with\nmultiple lines

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_FILE="$STATE_DIR/claude-queue.conf"

# Read hook input from stdin (shared by all handlers)
HOOK_INPUT=$(cat)

# Extract session_id from hook JSON input, fall back to env var
CLAUDE_SESSION_ID="${CLAUDE_SESSION_ID:-$(echo "$HOOK_INPUT" | jq -r '.session_id // empty')}"
if [[ -z "$CLAUDE_SESSION_ID" ]]; then
  echo "Error: session_id not found in hook input" >&2
  exit 1
fi

mkdir -p "$STATE_DIR"

SECTION="session.${CLAUDE_SESSION_ID}"
KEY="${SECTION}.item"

# --- Queue operations ---

# Read all items as NUL-delimited array
# Sets ITEMS array and ITEM_COUNT
read_items() {
  ITEMS=()
  ITEM_COUNT=0
  if [[ ! -f "$CONFIG_FILE" ]]; then
    return
  fi
  while IFS= read -r -d '' item; do
    ITEMS+=("$item")
  done < <(git config -f "$CONFIG_FILE" -z --get-all "$KEY" 2>/dev/null) || true
  ITEM_COUNT=${#ITEMS[@]}
}

queue_add() {
  local msg="$1"
  git config -f "$CONFIG_FILE" --add "$KEY" "$msg"
  read_items
  block_with_message "Queued ($ITEM_COUNT total): $(truncate_line "$msg")"
}

queue_list() {
  read_items
  if [[ "$ITEM_COUNT" -eq 0 ]]; then
    block_with_message "Queue is empty."
    return
  fi
  local msg=""
  for ((i = 0; i < ITEM_COUNT; i++)); do
    msg+="  $((i + 1)). $(truncate_line "${ITEMS[$i]}")"$'\n'
  done
  local auto_label="manual"
  is_auto && auto_label="auto"
  msg+="($ITEM_COUNT items, $auto_label)"
  block_with_message "$msg"
}

queue_del() {
  local n="$1"
  read_items
  if [[ "$n" -lt 1 || "$n" -gt "$ITEM_COUNT" ]]; then
    block_with_message "Invalid index: $n (queue has $ITEM_COUNT items)"
    return 1
  fi
  local deleted="${ITEMS[$((n - 1))]}"
  # Remove all items then re-add without the deleted one
  git config -f "$CONFIG_FILE" --unset-all "$KEY" 2>/dev/null || true
  for ((i = 0; i < ITEM_COUNT; i++)); do
    if [[ "$i" -ne $((n - 1)) ]]; then
      git config -f "$CONFIG_FILE" --add "$KEY" "${ITEMS[$i]}"
    fi
  done
  block_with_message "Deleted #$n: $(truncate_line "$deleted")"
}

queue_clear() {
  read_items
  git config -f "$CONFIG_FILE" --remove-section "$SECTION" 2>/dev/null || true
  block_with_message "Cleared $ITEM_COUNT items from queue."
}

queue_pop() {
  read_items
  if [[ "$ITEM_COUNT" -eq 0 ]]; then
    return 1
  fi
  local first="${ITEMS[0]}"
  # Remove all items then re-add without the first one
  git config -f "$CONFIG_FILE" --unset-all "$KEY" 2>/dev/null || true
  for ((i = 1; i < ITEM_COUNT; i++)); do
    git config -f "$CONFIG_FILE" --add "$KEY" "${ITEMS[$i]}"
  done
  echo "$first"
}

# --- Auto-dequeue flag ---

is_auto() {
  local val
  val=$(git config -f "$CONFIG_FILE" --get "${SECTION}.auto" 2>/dev/null) || true
  [[ "$val" == "true" ]]
}

set_auto() {
  local val="$1"
  git config -f "$CONFIG_FILE" "${SECTION}.auto" "$val"
}

# Truncate multiline message to first line with ... suffix
truncate_line() {
  local msg="$1"
  local first_line="${msg%%$'\n'*}"
  if [[ "$first_line" != "$msg" ]]; then
    echo "${first_line} ..."
  else
    echo "$msg"
  fi
}

# Output JSON to block prompt and show message to user via reason field
block_with_message() {
  local msg="$1"
  jq -n --arg m "$msg" '{
    "decision": "block",
    "reason": $m
  }'
  exit 0
}

show_help() {
  block_with_message "claude-queue — task queue for Claude Code

Commands:
  :qu MESSAGE    Add MESSAGE to the queue
  :qu            Show queued items (alias: :qu list)
  :qu del N      Delete Nth item
  :qu clear      Clear the queue
  :qu next       Dequeue and execute the next item
  :qu run        Start running the queue (auto-dequeue on task completion)
  :qu stop       Stop running the queue
  :qu help       Show this help"
}

# --- Hook handlers ---

on_prompt() {
  local prompt
  prompt=$(echo "$HOOK_INPUT" | jq -r '.prompt // empty')

  if [[ -z "$prompt" ]]; then
    exit 0
  fi

  # Check if the prompt is :qu (with optional trailing whitespace)
  local trimmed
  trimmed=$(printf '%s' "$prompt" | sed 's/[[:space:]]*$//')
  if [[ "$trimmed" == ":qu" ]]; then
    queue_list
  fi

  if [[ "$prompt" == ":qu "* ]]; then
    local body="${prompt#:qu }"

    case "$body" in
      list)
        queue_list
        ;;
      del\ [0-9]*)
        local n="${body#del }"
        queue_del "$n" || true
        ;;
      clear)
        queue_clear
        ;;
      next)
        local next
        if next=$(queue_pop); then
          read_items
          jq -n --arg msg "$next" --argjson r "$ITEM_COUNT" \
            --arg sm "Dequeuing ($ITEM_COUNT remaining): $(truncate_line "$next")" '{
            "systemMessage": $sm,
            "hookSpecificOutput": {
              "hookEventName": "UserPromptSubmit",
              "additionalContext": ("The user typed \":qu next\" which is a queue command, not an instruction. Ignore the prompt text. Instead, execute the following dequeued task (" + ($r | tostring) + " remaining in queue):\n\n" + $msg)
            }
          }'
          exit 0
        else
          block_with_message "Queue is empty."
        fi
        ;;
      run)
        set_auto true
        # If queue has items, immediately dequeue and execute
        local next
        if next=$(queue_pop); then
          read_items
          jq -n --arg msg "$next" --argjson r "$ITEM_COUNT" \
            --arg sm "Running queue ($ITEM_COUNT remaining): $(truncate_line "$next")" '{
            "systemMessage": $sm,
            "hookSpecificOutput": {
              "hookEventName": "UserPromptSubmit",
              "additionalContext": ("The user typed \":qu run\" which is a queue command, not an instruction. Ignore the prompt text. Instead, execute the following dequeued task (" + ($r | tostring) + " remaining in queue):\n\n" + $msg)
            }
          }'
          exit 0
        else
          block_with_message "Queue run enabled, but queue is empty. Add tasks with :qu MESSAGE."
        fi
        ;;
      stop)
        set_auto false
        block_with_message "Queue run stopped."
        ;;
      help)
        show_help
        ;;
      *)
        queue_add "$body"
        ;;
    esac
  fi

  # Not a :qu command — pass through, but show queue status if non-empty
  read_items
  if [[ "$ITEM_COUNT" -gt 0 ]]; then
    local next_preview
    next_preview=$(truncate_line "${ITEMS[0]}")
    jq -n --arg n "$next_preview" --argjson c "$ITEM_COUNT" '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": ("claude-queue: " + ($c | tostring) + " queued. Next: " + $n)
      }
    }'
  fi
  exit 0
}

on_stop() {
  read_items
  if [[ "$ITEM_COUNT" -eq 0 ]]; then
    exit 0
  fi

  if ! is_auto; then
    # Manual mode: just notify
    local next_preview
    next_preview=$(truncate_line "${ITEMS[0]}")
    echo "claude-queue: $ITEM_COUNT queued. Use :qu next to dequeue. Next: $next_preview" >&2
    exit 0
  fi

  # Auto mode: pop and block stop to continue with next task
  local next
  if next=$(queue_pop); then
    read_items
    jq -n --arg msg "$next" --argjson r "$ITEM_COUNT" '{
      "decision": "block",
      "reason": ("The user queued this task earlier via claude-queue (" + ($r | tostring) + " remaining). Execute it now:\n\n" + $msg),
      "systemMessage": ("auto-dequeuing (" + ($r | tostring) + " remaining)")
    }'
  fi
  exit 0
}

# --- Main dispatch ---

case "${1:-}" in
  on-prompt) on_prompt ;;
  on-stop)   on_stop ;;
  *)
    echo "Usage: queue.sh {on-prompt|on-stop}" >&2
    exit 1
    ;;
esac
