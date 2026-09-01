#!/usr/bin/env bash

set -euo pipefail

version=''
changelog_file=''
max_length=5000

usage() {
  printf 'Usage: %s --version VERSION --file CHANGELOG.md [--max-length CHARACTERS]\n' "${0##*/}" >&2
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
    --max-length)
      (($# >= 2)) || usage
      max_length="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

[[ -n "$version" && -n "$changelog_file" && -f "$changelog_file" ]] || usage
[[ "$max_length" =~ ^[1-9][0-9]*$ ]] || usage

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

if ((${#notes} > max_length)); then
  printf 'Release notes for %s exceed the %s-character limit.\n' \
    "$version" "$max_length" >&2
  exit 1
fi

printf '%s\n' "$notes"
