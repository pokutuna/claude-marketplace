#!/usr/bin/env bash
set -o pipefail

result_file=$1
transcript_file=$2
shift 2

codex exec --output-last-message "$result_file" "$@" 2>&1 | tee -a "$transcript_file"
