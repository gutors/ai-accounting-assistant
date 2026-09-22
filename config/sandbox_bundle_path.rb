# Cursor's command sandbox sets BUNDLE_PATH to an empty gem cache under
# cursor-sandbox-cache. This app's gems live in the default Bundler location.
# Leaving the variable set makes bin/lefthook fail on every sandboxed commit
# ("Could not find ... in locally installed gems"). Drop those overrides
# before bundler/setup. A BUNDLE_PATH outside that cache is left alone.
SANDBOX_BUNDLE_MARK = "cursor-sandbox-cache"

%w[BUNDLE_PATH GEM_SPEC_CACHE].each do |key|
  value = ENV[key]
  ENV.delete(key) if value&.include?(SANDBOX_BUNDLE_MARK)
end
