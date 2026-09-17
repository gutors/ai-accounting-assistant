require "rails_helper"

RSpec.describe "Application config" do
  it "uses PostgreSQL" do
    expect(ActiveRecord::Base.connection.adapter_name).to eq("PostgreSQL")
  end

  it "loads Active Storage Disk test service, skips Drive and Kamal" do
    expect(defined?(ActiveStorage::Engine)).not_to be_nil
    expect(Rails.application.config.active_storage.service).to eq(:test)
    expect(ActiveStorage::Blob.service).to be_a(ActiveStorage::Service::DiskService)
    expect(ActiveStorage::Blob.service.root.to_s).to include("tmp/storage")
    expect(Rails.root.join("config/storage.yml").read).not_to match(/Drive/)
    expect(Rails.root.join("config/deploy.yml")).not_to exist
    gemfile = Rails.root.join("Gemfile").read
    expect(gemfile).not_to match(/^\s*gem ["']kamal["']/)
  end
end
