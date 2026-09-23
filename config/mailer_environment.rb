module MailerEnvironment
  def self.apply!(config)
    config.action_mailer.default_url_options = { host: ENV["MAILER_HOST"] }

    address = ENV["SMTP_ADDRESS"].to_s
    return if address.blank?

    port = ENV["SMTP_PORT"].to_s.strip
    config.action_mailer.smtp_settings = {
      address: address,
      port: port.empty? ? 587 : Integer(port),
      user_name: ENV["SMTP_USER_NAME"],
      password: ENV["SMTP_PASSWORD"],
      authentication: :plain
    }
  end
end
