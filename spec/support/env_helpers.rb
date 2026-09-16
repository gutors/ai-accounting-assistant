module EnvHelpers
  def with_env(hash)
    previous = hash.keys.index_with { |key| ENV[key] }
    hash.each do |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
    yield
  ensure
    previous.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end
end
