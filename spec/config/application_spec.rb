require "rails_helper"

RSpec.describe "Application config" do
  it "uses PostgreSQL, skips Active Storage, skips Kamal" do
    expect(ActiveRecord::Base.connection.adapter_name).to eq("PostgreSQL")
    expect(defined?(ActiveStorage::Engine)).to be_nil
    expect(Rails.root.join("config/deploy.yml")).not_to exist
    expect(Rails.root.join("config/deploy.yml")).not_to exist
    gemfile = Rails.root.join("Gemfile").read
    expect(gemfile).not_to match(/^\s*gem ["']kamal["']/)
  end
end
