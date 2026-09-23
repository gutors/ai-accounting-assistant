require "rails_helper"
require Rails.root.join("config/mailer_environment")

RSpec.describe MailerEnvironment do
  def apply_mailer
    config = ActiveSupport::OrderedOptions.new
    config.action_mailer = ActiveSupport::OrderedOptions.new
    described_class.apply!(config)
    config.action_mailer
  end

  it "mail delivery errors are raised outside test and test uses the test delivery" do
    development = Rails.root.join("config/environments/development.rb").read
    production = Rails.root.join("config/environments/production.rb").read

    expect(development).to include("config.action_mailer.raise_delivery_errors = true")
    expect(production).to include("config.action_mailer.raise_delivery_errors = true")
    expect(Rails.application.config.action_mailer.delivery_method).to eq(:test)
    expect(Rails.application.config.action_mailer.default_url_options[:host]).to eq("example.com")
  end

  it "production smtp settings follow SMTP_ADDRESS" do
    production = Rails.root.join("config/environments/production.rb").read
    expect(production).to include("MailerEnvironment.apply!")

    with_env(
      "SMTP_ADDRESS" => "smtp.example.test",
      "SMTP_PORT" => "2525",
      "SMTP_USER_NAME" => "user",
      "SMTP_PASSWORD" => "secret",
      "MAILER_HOST" => "fechamento.example"
    ) do
      expect(apply_mailer.smtp_settings).to eq(
        address: "smtp.example.test",
        port: 2525,
        user_name: "user",
        password: "secret",
        authentication: :plain
      )
    end

    with_env(
      "SMTP_ADDRESS" => "smtp.example.test",
      "SMTP_PORT" => "",
      "SMTP_USER_NAME" => "user",
      "SMTP_PASSWORD" => "secret"
    ) do
      expect(apply_mailer.smtp_settings[:port]).to eq(587)
    end

    with_env("SMTP_ADDRESS" => "") do
      expect(apply_mailer.smtp_settings).to be_nil
    end
  end

  it "development and production mail host is MAILER_HOST" do
    development = Rails.root.join("config/environments/development.rb").read
    production = Rails.root.join("config/environments/production.rb").read
    expect(development).to include("MailerEnvironment.apply!")
    expect(production).to include("MailerEnvironment.apply!")

    with_env("MAILER_HOST" => "fechamento.example", "SMTP_ADDRESS" => nil) do
      expect(apply_mailer.default_url_options[:host]).to eq("fechamento.example")
    end
  end

  it "README setup note names the mail and administrator env vars" do
    note = Rails.root.join("README.md").read
    %w[ADMINISTRATOR_EMAIL MAIL_FROM MAILER_HOST SMTP_ADDRESS SMTP_PORT SMTP_USER_NAME SMTP_PASSWORD].each do |key|
      expect(note).to include(key)
    end
  end
end
