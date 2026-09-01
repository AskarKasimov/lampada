#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

ROOT = File.expand_path("..", __dir__)
WORKFLOW_PATH = File.join(ROOT, ".github/workflows/release-submit.yml")
FASTFILE_PATH = File.join(ROOT, "fastlane/Fastfile")

def fail!(message)
  warn "release CD contract: #{message}"
  exit 1
end

def require_value(container, key, context)
  value = container[key]
  fail!("missing #{context}.#{key}") if value.nil?

  value
end

fail!("missing #{WORKFLOW_PATH}") unless File.file?(WORKFLOW_PATH)
fail!("missing #{FASTFILE_PATH}") unless File.file?(FASTFILE_PATH)

workflow = YAML.safe_load(File.read(WORKFLOW_PATH), aliases: true)
jobs = require_value(workflow, "jobs", "workflow")

tag_pattern = require_value(require_value(workflow, true, "workflow"), "push", "workflow.on").fetch("tags")
fail!("does not trigger on release tags") unless tag_pattern.include?("v*.*.*")

validate = require_value(jobs, "validate-release", "jobs")
fail!("validate-release must not access an Environment") if validate.key?("environment")

%w[submit-rustore submit-appstore].each do |job_name|
  job = require_value(jobs, job_name, "jobs")
  dependencies = Array(job["needs"])
  fail!("#{job_name} does not require validate-release") unless dependencies.include?("validate-release")
end

appstore_job = jobs.fetch("submit-appstore")
fail!("submit-appstore must use appstore-production") unless appstore_job["environment"] == "appstore-production"

fastfile = File.read(FASTFILE_PATH)
fail!("App Store lane does not submit for review") unless fastfile.match?(/submit_for_review:\s*true/)
fail!("App Store lane enables automatic release") unless fastfile.match?(/automatic_release:\s*false/)

puts "release CD contract: ok"
