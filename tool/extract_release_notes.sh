#!/usr/bin/env bash

set -euo pipefail

version=''
changelog_file=''

usage() {
  printf 'Usage: %s --version VERSION --file CHANGELOG.md\n' "${0##*/}" >&2
  exit 2
}

while (($# > 0)); do
  case "$1" in
    --version)
      (($# >= 2)) || usage
      version="$2"
      shift 2
      ;;
    --file)
      (($# >= 2)) || usage
      changelog_file="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

[[ -n "$version" && -n "$changelog_file" && -f "$changelog_file" ]] || usage

notes="$(awk -v version="$version" '
  BEGIN {
    heading = "## [" version "]"
  }
  $0 == heading || index($0, heading " - ") == 1 {
    found = 1
    next
  }
  found && /^## / {
    exit
  }
  found {
    if (!started && $0 ~ /^[[:space:]]*$/) {
      next
    }
    if ($0 ~ /[^[:space:]]/) {
      started = 1
    }
    if (started) {
      print
    }
  }
  END {
    if (!found) {
      print "Release notes section " heading " is missing." > "/dev/stderr"
      exit 1
    }
    if (!started) {
      print "Release notes section " heading " is empty." > "/dev/stderr"
      exit 1
    }
  }
' "$changelog_file")"

if ((${#notes} > 5000)); then
  printf 'Release notes for %s exceed the 5000-character limit.\n' "$version" >&2
  exit 1
fi

printf '%s\n' "$notes"
