# frozen_string_literal: true

require "rbconfig"

RSpec.describe "Cursor sandbox bundle path" do
  root = File.expand_path("../..", __dir__)

  it "drops BUNDLE_PATH and GEM_SPEC_CACHE that point at cursor-sandbox-cache" do
    output = sandbox_bundle_env(
      root,
      "BUNDLE_PATH" => "/tmp/cursor-sandbox-cache/abc/bundle",
      "GEM_SPEC_CACHE" => "/tmp/cursor-sandbox-cache/abc/gem-specs"
    )

    expect(output).to eq("nil\nnil\n")
  end

  it "keeps a BUNDLE_PATH outside the sandbox cache" do
    output = sandbox_bundle_env(
      root,
      "BUNDLE_PATH" => "/tmp/vendor/bundle",
      "GEM_SPEC_CACHE" => "/tmp/gem-specs"
    )

    expect(output).to eq("\"/tmp/vendor/bundle\"\n\"/tmp/gem-specs\"\n")
  end

  it "loads the guard before bundler/setup in direct binstubs and boot" do
    %w[bin/lefthook bin/rubocop bin/erb_lint bin/rspec bin/brakeman bin/thrust config/boot.rb].each do |relative|
      source = File.read(File.join(root, relative))
      guard = source.index("sandbox_bundle_path")
      setup = source.index('require "bundler/setup"')
      expect(guard).to be < setup
    end
  end

  def sandbox_bundle_env(root, env)
    script = File.join(root, "config/sandbox_bundle_path.rb")
    # This example runs inside a process that already loaded Bundler, which
    # exports BUNDLER_SETUP. Ruby then requires that file before -e. Drop it so
    # the child measures the guard itself.
    isolated = env.merge("BUNDLE_GEMFILE" => nil, "BUNDLER_SETUP" => nil, "RUBYOPT" => nil)
    IO.popen([ isolated, RbConfig.ruby, "--disable=gems", "-e", <<~RUBY ], &:read)
      require #{script.inspect}
      puts ENV["BUNDLE_PATH"].inspect
      puts ENV["GEM_SPEC_CACHE"].inspect
    RUBY
  end
end
