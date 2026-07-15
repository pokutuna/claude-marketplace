#!/usr/bin/env bash
# Emit the RESULT_FILE and TRANSCRIPT_FILE paths for this session, one per line.
# Line 1: RESULT_FILE (.md)  — final message from --output-last-message
# Line 2: TRANSCRIPT_FILE (.jsonl) — JSONL event log
base="${TMPDIR:-/tmp}"
base="${base%/}"
stamp="codex-review-$(date +%Y%m%d-%H%M%S)"
echo "$base/$stamp.md"
echo "$base/$stamp.jsonl"
