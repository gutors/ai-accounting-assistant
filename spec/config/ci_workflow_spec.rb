require "rails_helper"
require "yaml"

RSpec.describe "CI workflow" do
  it "ci builds tailwind before rspec" do
    workflow = YAML.safe_load(Rails.root.join(".github/workflows/ci.yml").read)
    runs = workflow.fetch("jobs").fetch("test").fetch("steps").map { |step| step["run"].to_s }

    build_index = runs.index { |run| run.include?("bin/rails tailwindcss:build") }
    rspec_index = runs.index { |run| run.include?("bin/rspec") }

    expect(build_index).not_to be_nil
    expect(rspec_index).not_to be_nil
    expect(build_index).to be < rspec_index
  end
end
