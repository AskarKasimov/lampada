#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

ROOT = File.expand_path("..", __dir__)
ORCHESTRATOR_WORKFLOW_PATH = File.join(ROOT, ".github/workflows/release-validate.yml")
RUSTORE_WORKFLOW_PATH = File.join(ROOT, ".github/workflows/release-rustore.yml")
TESTFLIGHT_WORKFLOW_PATH = File.join(ROOT, ".github/workflows/release-testflight.yml")
FASTFILE_PATH = File.join(ROOT, "fastlane/Fastfile")
RUSTORE_PUBLISH_PATH = File.join(ROOT, "tool/rustore_publish.sh")

def fail!(message)
  warn "release CD contract: #{message}"
  exit 1
end

def require_value(container, key, context)
  value = container[key]
  fail!("missing #{context}.#{key}") if value.nil?

  value
end

fail!("missing #{ORCHESTRATOR_WORKFLOW_PATH}") unless File.file?(ORCHESTRATOR_WORKFLOW_PATH)
fail!("missing #{RUSTORE_WORKFLOW_PATH}") unless File.file?(RUSTORE_WORKFLOW_PATH)
fail!("missing #{TESTFLIGHT_WORKFLOW_PATH}") unless File.file?(TESTFLIGHT_WORKFLOW_PATH)
fail!("missing #{FASTFILE_PATH}") unless File.file?(FASTFILE_PATH)
fail!("missing #{RUSTORE_PUBLISH_PATH}") unless File.file?(RUSTORE_PUBLISH_PATH)

def load_workflow(path)
  workflow = YAML.safe_load(File.read(path), aliases: true)
  jobs = require_value(workflow, "jobs", "workflow")

  [workflow, jobs]
end

orchestrator_workflow, orchestrator_jobs = load_workflow(ORCHESTRATOR_WORKFLOW_PATH)
tag_pattern = require_value(require_value(orchestrator_workflow, true, "workflow"), "push", "workflow.on").fetch("tags")
fail!("release validation does not trigger on release tags") unless tag_pattern.include?("v*.*.*")

validate = require_value(orchestrator_jobs, "validate-release", "jobs")
fail!("release validation must not access an Environment") if validate.key?("environment")

rustore_workflow, rustore_jobs = load_workflow(RUSTORE_WORKFLOW_PATH)
testflight_workflow, testflight_jobs = load_workflow(TESTFLIGHT_WORKFLOW_PATH)

%w[release-rustore.yml release-testflight.yml].zip([rustore_workflow, testflight_workflow]).each do |filename, workflow|
  fail!("#{filename} is not reusable") unless require_value(workflow, true, "workflow").key?("workflow_call")
end

fail!("RuStore workflow has unexpected TestFlight job") if rustore_jobs.key?("upload-testflight")
fail!("TestFlight workflow has unexpected RuStore job") if testflight_jobs.key?("submit-rustore")

{
  "submit-rustore" => "./.github/workflows/release-rustore.yml",
  "upload-testflight" => "./.github/workflows/release-testflight.yml",
}.each do |job_name, workflow_path|
  job = require_value(orchestrator_jobs, job_name, "jobs")
  dependencies = Array(job["needs"])
  fail!("#{job_name} does not require validate-release") unless dependencies.include?("validate-release")
  fail!("#{job_name} does not call #{workflow_path}") unless job["uses"] == workflow_path
end

rustore_job = rustore_jobs.fetch("submit-rustore")
fail!("submit-rustore must use rustore-production") unless rustore_job["environment"] == "rustore-production"
fail!("RuStore workflow has no isolated concurrency") unless rustore_workflow.dig("concurrency", "group") == "rustore-production"

testflight_job = testflight_jobs.fetch("upload-testflight")
fail!("upload-testflight must use appstore-production") unless testflight_job["environment"] == "appstore-production"
fail!("TestFlight workflow has no isolated concurrency") unless testflight_workflow.dig("concurrency", "group") == "testflight-production"

fastfile = File.read(FASTFILE_PATH)
fail!("TestFlight lane does not upload a build") unless fastfile.match?(/upload_to_testflight\s*\(/)
fail!("TestFlight lane can distribute the build") unless fastfile.match?(/skip_submission:\s*true/)
fail!("TestFlight lane waits for build processing") unless fastfile.match?(/skip_waiting_for_build_processing:\s*true/)
fail!("TestFlight lane can submit an App Store version") if fastfile.match?(/upload_to_app_store|submit_for_review|automatic_release/)

rustore_script = File.read(RUSTORE_PUBLISH_PATH)
fail!("RuStore script submits the draft for moderation") if rustore_script.match?(%r{/commit\?})

puts "release CD contract: ok"
