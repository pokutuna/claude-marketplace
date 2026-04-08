#!/usr/bin/env bats

# Test suite for queue.sh
# Run: bats queue/test/queue.bats

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
QUEUE_SH="$SCRIPT_DIR/bin/queue.sh"

setup() {
  export XDG_STATE_HOME="$BATS_TEST_TMPDIR/state"
  export CLAUDE_SESSION_ID="bats-test-$$"
  mkdir -p "$XDG_STATE_HOME"
  CONFIG_FILE="$XDG_STATE_HOME/claude-queue.conf"
}

teardown() {
  rm -rf "$BATS_TEST_TMPDIR/state"
}

# Helper: run on-prompt with a given prompt string
prompt() {
  jq -n --arg p "$1" --arg s "$CLAUDE_SESSION_ID" '{prompt: $p, session_id: $s}' | "$QUEUE_SH" on-prompt
}

# Helper: run on-stop with session_id
stop() {
  jq -n --arg s "$CLAUDE_SESSION_ID" '{session_id: $s}' | "$QUEUE_SH" on-stop
}

# Helper: add items to queue directly via git config
enqueue() {
  local key="session.${CLAUDE_SESSION_ID}.item"
  for msg in "$@"; do
    git config -f "$CONFIG_FILE" --add "$key" "$msg"
  done
}

# Helper: check JSON output has decision: block and systemMessage
assert_blocked_with() {
  local expected="$1"
  echo "$output" | jq -e '.decision == "block"' >/dev/null
  [[ "$output" == *"$expected"* ]]
}

# --- session_id ---

@test "fails without session_id" {
  unset CLAUDE_SESSION_ID
  run "$QUEUE_SH" on-prompt <<< '{"prompt":"hello"}'
  [ "$status" -eq 1 ]
  [[ "$output" == *"session_id not found"* ]]
}

# --- :qu add ---

@test ":qu adds message to queue" {
  run prompt ":qu fix the tests"
  [ "$status" -eq 0 ]
  assert_blocked_with "Queued (1 total): fix the tests"
  [ "$(git config -f "$CONFIG_FILE" --get-all "session.${CLAUDE_SESSION_ID}.item")" = "fix the tests" ]
}

@test ":qu adds multiple messages" {
  enqueue "task A" "task B"
  run prompt ":qu task C"
  [ "$status" -eq 0 ]
  assert_blocked_with "Queued (3 total): task C"
}

# --- :qu list ---

@test ":qu list on empty queue" {
  run prompt ":qu list"
  [ "$status" -eq 0 ]
  assert_blocked_with "Queue is empty."
}

@test ":qu list shows numbered items" {
  enqueue "alpha" "beta"
  run prompt ":qu list"
  [ "$status" -eq 0 ]
  assert_blocked_with "1. alpha"
  [[ "$output" == *"2. beta"* ]]
  [[ "$output" == *"2 items, manual"* ]]
}

# --- :qu del ---

@test ":qu del removes item by index" {
  enqueue "first" "second" "third"
  run prompt ":qu del 2"
  [ "$status" -eq 0 ]
  assert_blocked_with "Deleted #2: second"
  # Verify remaining
  run prompt ":qu list"
  [[ "$output" == *"1. first"* ]]
  [[ "$output" == *"2. third"* ]]
}

@test ":qu del with invalid index" {
  enqueue "only"
  run prompt ":qu del 5"
  [ "$status" -eq 0 ]
  assert_blocked_with "Invalid index: 5"
}

# --- :qu clear ---

@test ":qu clear empties the queue" {
  enqueue "a" "b"
  run prompt ":qu clear"
  [ "$status" -eq 0 ]
  assert_blocked_with "Cleared 2 items"
  run prompt ":qu list"
  assert_blocked_with "Queue is empty."
}

# --- :qu next ---

@test ":qu next dequeues first item with additionalContext" {
  enqueue "do this" "then that"
  run prompt ":qu next"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null
  [[ "$output" == *"do this"* ]]
  [[ "$output" == *"Dequeuing"* ]]
}

@test ":qu next on empty queue" {
  run prompt ":qu next"
  [ "$status" -eq 0 ]
  assert_blocked_with "Queue is empty."
}

# --- :qu help ---

@test ":qu help shows usage" {
  run prompt ":qu help"
  [ "$status" -eq 0 ]
  assert_blocked_with "claude-queue"
  [[ "$output" == *":qu MESSAGE"* ]]
  [[ "$output" == *":qu list"* ]]
  [[ "$output" == *":qu del N"* ]]
  [[ "$output" == *":qu next"* ]]
}

@test ":qu with no argument shows list" {
  enqueue "alpha"
  run prompt ":qu "
  [ "$status" -eq 0 ]
  assert_blocked_with "1. alpha"
}

@test "bare :qu shows list" {
  run prompt ":qu"
  [ "$status" -eq 0 ]
  assert_blocked_with "Queue is empty."
}

# --- :qu run / :qu stop ---

@test ":qu run with items dequeues immediately" {
  enqueue "first task" "second task"
  run prompt ":qu run"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Running queue"* ]]
  [[ "$output" == *"first task"* ]]
  # auto flag should be set
  local val
  val=$(git config -f "$CONFIG_FILE" --get "session.${CLAUDE_SESSION_ID}.auto")
  [ "$val" = "true" ]
}

@test ":qu run with empty queue blocks" {
  run prompt ":qu run"
  [ "$status" -eq 0 ]
  assert_blocked_with "queue is empty"
}

@test ":qu stop disables auto-dequeue" {
  prompt ":qu run" >/dev/null 2>&1 || true
  enqueue "task"
  prompt ":qu run" >/dev/null 2>&1
  run prompt ":qu stop"
  [ "$status" -eq 0 ]
  assert_blocked_with "Queue run stopped"
}

@test ":qu list shows auto status" {
  enqueue "task"
  git config -f "$CONFIG_FILE" "session.${CLAUDE_SESSION_ID}.auto" "true"
  run prompt ":qu list"
  [[ "$output" == *"auto"* ]]
}

# --- on-stop ---

@test "on-stop notifies in manual mode (default)" {
  enqueue "pending task"
  run stop
  [ "$status" -eq 0 ]
  [[ "$output" == *"Use :qu next"* ]]
  # Queue should NOT be popped
  local count
  count=$(git config -f "$CONFIG_FILE" --get-all "session.${CLAUDE_SESSION_ID}.item" | wc -l | tr -d ' ')
  [ "$count" = "1" ]
}

@test "on-stop auto-dequeues when auto is enabled" {
  enqueue "auto task" "next auto"
  git config -f "$CONFIG_FILE" "session.${CLAUDE_SESSION_ID}.auto" "true"
  local stdout
  stdout=$(stop 2>/dev/null)
  echo "$stdout" | jq -e '.decision == "block"' >/dev/null
  [[ "$stdout" == *"auto task"* ]]
  [[ "$stdout" == *"1 remaining"* ]]
}

@test "on-stop does nothing when queue is empty" {
  run stop
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Pass-through with queue status ---

@test "normal prompt passes through with queue status" {
  enqueue "pending task"
  run prompt "do something else"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null
  [[ "$output" == *"1 queued"* ]]
  [[ "$output" == *"pending task"* ]]
}

@test "normal prompt passes through silently when queue is empty" {
  run prompt "just a normal prompt"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Multiline messages ---

@test ":qu handles multiline message" {
  run prompt ":qu line one
line two
line three"
  [ "$status" -eq 0 ]
  assert_blocked_with "Queued (1 total): line one ..."
  local stored
  stored=$(git config -f "$CONFIG_FILE" --get "session.${CLAUDE_SESSION_ID}.item")
  [[ "$stored" == *"line one"* ]]
  [[ "$stored" == *"line two"* ]]
  [[ "$stored" == *"line three"* ]]
}

@test ":qu list truncates multiline messages" {
  enqueue "short task" "first line
second line
third line"
  run prompt ":qu list"
  [ "$status" -eq 0 ]
  [[ "$output" == *"1. short task"* ]]
  [[ "$output" == *"2. first line ..."* ]]
  [[ "$output" != *"second line"* ]]
}

# --- Edge cases ---

@test "non :qu prefix is not intercepted" {
  run prompt "queue something please"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test ":qu message with special characters" {
  run prompt ":qu fix bug in src/foo.ts (line 42)"
  [ "$status" -eq 0 ]
  assert_blocked_with "Queued"
}

@test "empty prompt is ignored" {
  run prompt ""
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
