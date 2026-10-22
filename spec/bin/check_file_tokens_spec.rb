# frozen_string_literal: true

require "fileutils"
require "open3"
require "tmpdir"

RSpec.describe "bin/check-file-tokens" do
  def script
    File.expand_path("../../bin/check-file-tokens", __dir__)
  end

  def git(dir, *args)
    stdout, stderr, status = Open3.capture3("git", *args, chdir: dir)
    raise "git #{args.join(' ')} failed: #{stderr}" unless status.success?
    stdout
  end

  def run_hook(dir)
    Open3.capture3(script, chdir: dir)
  end

  def repo_with(files)
    Dir.mktmpdir("check-file-tokens-") do |dir|
      git(dir, "init", "-q")
      git(dir, "config", "user.email", "hook@example.test")
      git(dir, "config", "user.name", "Hook Spec")
      git(dir, "config", "core.hooksPath", "/dev/null")

      files.each do |relative, contents|
        path = File.join(dir, relative)
        FileUtils.mkdir_p(File.dirname(path))
        File.binwrite(path, contents)
      end
      git(dir, "add", "--", *files.keys) unless files.empty?

      yield dir
    end
  end

  def over_limit_source
    "x" * ((5_000 * 4) + 4)
  end

  def under_limit_source
    "ok\n"
  end

  it "rejects a staged source file over 5000 tokens" do
    repo_with("app/models/too_big.rb" => over_limit_source) do |dir|
      stdout, stderr, status = run_hook(dir)

      expect(status.exitstatus).to eq(1)
      expect(stdout).to eq("")
      expect(stderr).to include("BLOCKED: staged file exceeds 5000 tokens")
      expect(stderr).to include("app/models/too_big.rb")
      expect(stderr).to include("20004 bytes = 5001 tokens")
      expect(stderr).to include("How to split, then restage")
      expect(stderr).to include("RSpec: examples for one action into spec/requests/<resource>_<action>_spec.rb")
      expect(stderr).to include("ERB: extract app/views/<resource>/_<name>.html.erb and render it.")
      expect(stderr).to include("Do not use git commit --no-verify")
    end
  end

  it "allows a staged source file at the 5000 token limit" do
    repo_with("app/models/exact.rb" => "x" * (5_000 * 4)) do |dir|
      _stdout, stderr, status = run_hook(dir)

      expect(status.exitstatus).to eq(0)
      expect(stderr).to eq("")
    end
  end

  it "ignores staged lockfiles and db/schema.rb even when they exceed 5000 tokens" do
    files = {
      "Gemfile.lock" => over_limit_source,
      "package-lock.json" => over_limit_source,
      "db/schema.rb" => over_limit_source
    }
    repo_with(files) do |dir|
      _stdout, stderr, status = run_hook(dir)

      expect(status.exitstatus).to eq(0)
      expect(stderr).to eq("")
    end
  end

  it "does not inspect an unstaged over-limit file" do
    repo_with("app/models/small.rb" => under_limit_source) do |dir|
      File.binwrite(File.join(dir, "app/models/unstaged.rb"), over_limit_source)

      _stdout, stderr, status = run_hook(dir)

      expect(status.exitstatus).to eq(0)
      expect(stderr).to eq("")
    end
  end
end
