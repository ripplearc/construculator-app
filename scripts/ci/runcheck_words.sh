#!/bin/bash

# Reads the words that follow "#RunCheck" in a comment. Source this file; it
# prints nothing by itself.
#   comment_has_runcheck_word <word>   succeeds when COMMENT_BODY has "#RunCheck <word>"

comment_has_runcheck_word() {
  echo "${COMMENT_BODY:-}" | grep -Eiq "(^|[[:space:]])#runcheck[[:space:]]+$1([[:space:]]|\$)"
}
