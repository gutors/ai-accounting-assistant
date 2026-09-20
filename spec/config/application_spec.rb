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

  it "test package archive writer is in-memory not Google" do
    expect(PackageArchiveWriter.current).to be_a(PackageArchiveWriter::Memory)
    expect(PackageArchiveWriter.current).not_to be_a(PackageArchiveWriter::Drive)
  end

  it "test identified consulta is the Fake" do
    expect(SefazConsulta.current).to be_a(SefazConsulta::Fake)
    expect(SefazConsulta.current).not_to be_a(SefazConsulta::Real)
  end

  it "test photo symbols is the Fake" do
    expect(PhotoSymbols.current).to be_a(PhotoSymbols::Fake)
    expect(PhotoSymbols.current).not_to be_a(PhotoSymbols::Real)
  end

  it "test photo fields is the Fake" do
    expect(PhotoFields.current).to be_a(PhotoFields::Fake)
    expect(PhotoFields.current).not_to be_a(PhotoFields::Real)
  end

  it "test public NFC-e consulta is the Fake" do
    expect(PublicNfceConsulta.current).to be_a(PublicNfceConsulta::Fake)
    expect(PublicNfceConsulta.current).not_to be_a(PublicNfceConsulta::Real)
  end

  it "Gemfile includes google-apis-drive_v3 and googleauth" do
    gemfile = Rails.root.join("Gemfile").read
    expect(gemfile).to include("google-apis-drive_v3")
    expect(gemfile).to include("googleauth")
  end

  it "production runtime image installs tesseract-ocr and tesseract-ocr-por" do
    dockerfile = Rails.root.join("Dockerfile").read
    base, = dockerfile.split("FROM base AS build", 2)

    expect(base).to include("tesseract-ocr")
    expect(base).to include("tesseract-ocr-por")
  end

  it "CI test job installs tesseract-ocr and tesseract-ocr-por before rspec" do
    ci = Rails.root.join(".github/workflows/ci.yml").read
    test_job = ci[/  test:.*?(?=\n  lint:|\z)/m]

    expect(test_job.index("tesseract-ocr")).to be < test_job.index("bin/rspec")
    expect(test_job.index("tesseract-ocr-por")).to be < test_job.index("bin/rspec")
  end
end
