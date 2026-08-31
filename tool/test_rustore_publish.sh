#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
client="$root_dir/tool/rustore_publish.sh"
test_dir="$(mktemp -d)"
mock_bin="$test_dir/mock-bin"
curl_log="$test_dir/curl.log"
private_key_plaintext='secret-private-key'
private_key_base64="$(printf '%s' "$private_key_plaintext" | base64 | tr -d '\n')"
api_base_url='https://api.example.test'
package_name='ru.lampada.lampada'
aab_file="$test_dir/app-release.aab"

cleanup() {
  rm -rf -- "$test_dir"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" != *"$needle"* ]] || fail "output must not contain: $needle"
}

assert_log_contains() {
  local needle="$1"
  grep -Fqx -- "$needle" "$curl_log" || fail "expected curl call: $needle"
}

assert_log_not_contains() {
  local needle="$1"
  ! grep -Fqx -- "$needle" "$curl_log" || fail "unexpected curl call: $needle"
}

mkdir -p "$mock_bin"
printf 'fake AAB\n' > "$aab_file"

cat > "$mock_bin/curl" <<'MOCK_CURL'
#!/usr/bin/env bash
set -euo pipefail

for argument in "$@"; do
  url="$argument"
  printf '%s\n' "$argument" >> "$CURL_LOG"
done

case "$url" in
  */public/auth|*/public/auth/)
    if [[ "${MOCK_AUTH_ERROR:-0}" == '1' ]]; then
      printf '%s\n' '{"code":"ERROR","message":"invalid key"}'
    else
      printf '%s\n' '{"code":"OK","body":{"jwe":"test-token","ttl":900}}'
    fi
    ;;
  */version/*/aab|*/commit\?priorityUpdate=0)
    if [[ "${MOCK_UPLOAD_ERROR:-0}" == '1' && "$url" == */aab ]]; then
      printf '%s\n' '{"code":"ERROR","message":"upload rejected"}'
    else
      printf '%s\n' '{"code":"OK","body":null}'
    fi
    ;;
  */version)
    printf '%s\n' '{"code":"OK","body":243242}'
    ;;
  *)
    printf 'unexpected URL: %s\n' "$url" >&2
    exit 64
    ;;
esac
MOCK_CURL

cat > "$mock_bin/openssl" <<'MOCK_OPENSSL'
#!/usr/bin/env bash
set -euo pipefail
cat >/dev/null
printf 'test-signature'
MOCK_OPENSSL
chmod +x "$mock_bin/curl" "$mock_bin/openssl"

run_client() {
  CURL_LOG="$curl_log" \
  CURL_BIN="$mock_bin/curl" \
  OPENSSL_BIN="$mock_bin/openssl" \
  RUSTORE_API_BASE_URL="$api_base_url" \
  RUSTORE_KEY_ID='123' \
  RUSTORE_PRIVATE_KEY="$private_key_base64" \
  "$client" \
    --aab "$aab_file" \
    --package "$package_name" \
    --whats-new 'Исправления ошибок' \
    "$@"
}

test_successful_submission() {
  : > "$curl_log"
  local output
  output="$(run_client 2>&1)" || fail "expected successful submission, got: $output"

  assert_contains "$output" 'version_id=243242'
  assert_contains "$output" 'status=submitted'
  assert_log_contains "$api_base_url/public/v1/application/$package_name/version/243242/aab"
  assert_log_contains "$api_base_url/public/v1/application/$package_name/version/243242/commit?priorityUpdate=0"
}

test_reuses_explicit_draft() {
  : > "$curl_log"
  local output
  output="$(run_client --draft-version-id 777 2>&1)" || fail "expected draft recovery, got: $output"

  assert_contains "$output" 'version_id=777'
  assert_log_not_contains "$api_base_url/public/v1/application/$package_name/version"
}

test_redacts_private_key_on_authentication_error() {
  : > "$curl_log"
  local output status
  set +e
  output="$(MOCK_AUTH_ERROR=1 run_client 2>&1)"
  status=$?
  set -e

  [[ "$status" -ne 0 ]] || fail 'authentication error must fail'
  assert_contains "$output" 'authorization failed'
  assert_not_contains "$output" "$private_key_plaintext"
  assert_not_contains "$output" "$private_key_base64"
}

test_reports_created_draft_id_after_upload_error() {
  : > "$curl_log"
  local output status
  set +e
  output="$(MOCK_UPLOAD_ERROR=1 run_client 2>&1)"
  status=$?
  set -e

  [[ "$status" -ne 0 ]] || fail 'upload error must fail'
  assert_contains "$output" 'draft_version_id=243242'
  assert_contains "$output" 'AAB upload failed'
}

test_successful_submission
test_reuses_explicit_draft
test_redacts_private_key_on_authentication_error
test_reports_created_draft_id_after_upload_error
printf 'PASS: rustore_publish.sh\n'
