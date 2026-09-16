# Rails 8 `allow_browser versions: :modern` rejects Rack::Test's default UA.
module ChromeUserAgent
  CHROME = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"

  def process(method, path, **kwargs)
    kwargs[:headers] = { "User-Agent" => CHROME }.merge(kwargs[:headers] || {})
    super
  end
end

RSpec.configure do |config|
  config.prepend ChromeUserAgent, type: :request
end
