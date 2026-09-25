#!/usr/bin/env ruby
# frozen_string_literal: true

require "open3"
require "tempfile"

SCRIPT = File.expand_path("extract_release_notes.sh", __dir__)

def run_notes(*arguments)
  Open3.capture3("bash", SCRIPT, *arguments)
end

Tempfile.create(["release-notes", ".md"]) do |changelog|
  changelog.write("## [1.2.3] - 2026-09-01\n\n#{"а" * 4_001}\n")
  changelog.flush

  output, error, status = run_notes("--version", "1.2.3", "--file", changelog.path)

  abort("RuStore default limit unexpectedly rejected notes: #{error}") unless status.success?
  abort("release notes were changed") unless output.strip.length == 4_001
end

puts "release notes contract: ok"
