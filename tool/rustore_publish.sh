#!/usr/bin/env bash
set -euo pipefail

CURL_BIN="${CURL_BIN:-curl}"
OPENSSL_BIN="${OPENSSL_BIN:-openssl}"
RUSTORE_API_BASE_URL="${RUSTORE_API_BASE_URL:-https://public-api.rustore.ru}"

aab=''
package_name=''
whats_new=''
draft_version_id=''
key_file=''

die() {
  printf 'RuStore submit: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  [[ -z "$key_file" ]] || rm -f -- "$key_file"
}
trap cleanup EXIT

require_option_value() {
  (($# >= 2)) || die "missing value for $1"
}

has_line_break() {
  [[ "$1" == *$'\n'* || "$1" == *$'\r'* ]]
}

base64_decode() {
  if base64 --help 2>&1 | grep -q -- '--decode'; then
    base64 --decode
  else
    base64 -D
  fi
}

api_error_message() {
  local response="$1"
  jq -r 'if type == "object" then (.message // "API rejected request") else "Invalid API response" end'     <<< "$response" 2>/dev/null | head -n 1
}

require_api_success() {
  local stage="$1"
  local response="$2"

  jq -e '.code == "OK"' >/dev/null 2>&1 <<< "$response" ||     die "$stage failed: $(api_error_message "$response")"
}

post_json() {
  local url="$1"
  local token="$2"
  local body="$3"

  "$CURL_BIN"     --silent     --show-error     --request POST     --header 'Content-Type: application/json'     --header "Public-Token: $token"     --data "$body"     "$url"
}

while (($#)); do
  case "$1" in
    --aab)
      require_option_value "$@"
      aab="$2"
      shift 2
      ;;
    --package)
      require_option_value "$@"
      package_name="$2"
      shift 2
      ;;
    --whats-new)
      require_option_value "$@"
      whats_new="$2"
      shift 2
      ;;
    --draft-version-id)
      require_option_value "$@"
      draft_version_id="$2"
      shift 2
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

[[ -n "$aab" && -f "$aab" && "$aab" == *.aab ]] ||   die 'provide an existing .aab file with --aab'
[[ -n "$package_name" && "$package_name" =~ ^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+$ ]] ||   die 'provide an Android package name with --package'
[[ -n "$whats_new" && ${#whats_new} -le 5000 ]] ||   die 'provide release notes of 1 to 5000 characters with --whats-new'
[[ -z "$draft_version_id" || "$draft_version_id" =~ ^[1-9][0-9]*$ ]] ||   die 'draft version ID must be a positive integer'

[[ -n "${RUSTORE_KEY_ID:-}" ]] || die 'missing RUSTORE_KEY_ID'
[[ -n "${RUSTORE_PRIVATE_KEY:-}" ]] || die 'missing RUSTORE_PRIVATE_KEY'
for value in "$package_name" "$whats_new" "$draft_version_id"   "$RUSTORE_KEY_ID" "$RUSTORE_PRIVATE_KEY"; do
  has_line_break "$value" && die 'options and secrets must not contain line breaks'
done

umask 077
key_file="$(mktemp)"
if ! printf '%s' "$RUSTORE_PRIVATE_KEY" | base64_decode > "$key_file"; then
  die 'RUSTORE_PRIVATE_KEY is not valid base64'
fi
[[ -s "$key_file" ]] || die 'RUSTORE_PRIVATE_KEY decodes to an empty key'

timestamp="$(date -u +'%Y-%m-%dT%H:%M:%S.000Z')"
if ! signature="$({ printf '%s' "${RUSTORE_KEY_ID}${timestamp}" |
  "$OPENSSL_BIN" dgst -sha512 -sign "$key_file" -binary | base64 | tr -d '\n'; })"; then
  die 'could not create authorization signature'
fi

auth_body="$(jq -cn   --arg keyId "$RUSTORE_KEY_ID"   --arg timestamp "$timestamp"   --arg signature "$signature"   '{keyId: $keyId, timestamp: $timestamp, signature: $signature}')"
if ! auth_response="$("$CURL_BIN"   --silent   --show-error   --request POST   --header 'Content-Type: application/json'   --data "$auth_body"   "$RUSTORE_API_BASE_URL/public/auth/")"; then
  die 'authorization request failed'
fi
if ! token="$(jq -er 'select(.code == "OK") | .body.jwe | select(type == "string" and length > 0)'   <<< "$auth_response" 2>/dev/null)"; then
  die "authorization failed: $(api_error_message "$auth_response")"
fi

package_path="$(printf '%s' "$package_name" | jq -sRr @uri)"
if [[ -z "$draft_version_id" ]]; then
  draft_body="$(jq -cn --arg whatsNew "$whats_new"     '{whatsNew: $whatsNew, publishType: "MANUAL"}')"
  if ! draft_response="$(post_json     "$RUSTORE_API_BASE_URL/public/v1/application/$package_path/version"     "$token"     "$draft_body")"; then
    die 'draft creation request failed'
  fi
  require_api_success 'draft creation' "$draft_response"
  if ! draft_version_id="$(jq -er 'select(.code == "OK") | .body | select(type == "number" and . > 0) | floor'     <<< "$draft_response" 2>/dev/null)"; then
    die 'draft creation failed: response has no version ID'
  fi
fi

if ! upload_response="$("$CURL_BIN"   --silent   --show-error   --request POST   --header "Public-Token: $token"   --form "file=@$aab"   "$RUSTORE_API_BASE_URL/public/v1/application/$package_path/version/$draft_version_id/aab")"; then
  die "AAB upload request failed for draft $draft_version_id"
fi
require_api_success 'AAB upload' "$upload_response"

if ! submit_response="$("$CURL_BIN"   --silent   --show-error   --request POST   --header "Public-Token: $token"   "$RUSTORE_API_BASE_URL/public/v1/application/$package_path/version/$draft_version_id/commit?priorityUpdate=0")"; then
  die "moderation submission request failed for draft $draft_version_id"
fi
require_api_success 'moderation submission' "$submit_response"

printf 'version_id=%s\nstatus=submitted\n' "$draft_version_id"
