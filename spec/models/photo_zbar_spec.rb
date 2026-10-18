require "rails_helper"

RSpec.describe PhotoZbar, type: :model do
  def png
    Rails.root.join("spec/fixtures/files/ocr/blank.png").binread
  end

  def status(exitstatus)
    instance_double(Process::Status, success?: exitstatus.zero?, exitstatus:)
  end

  it "scan parses stdout on zbarimg exit 0" do
    allow(Open3).to receive(:capture3).and_return([ "CODE-128:43260511222333000181550010000000011123456781\n", "", status(0) ])

    expect(PhotoZbar.scan(png)).to eq([ [ "CODE-128", "43260511222333000181550010000000011123456781" ] ])
  end

  it "scan treats zbarimg exit 1 as miss" do
    allow(Open3).to receive(:capture3).and_return([ "CODE-128:should-not-parse\n", "", status(1) ])

    expect(PhotoZbar.scan(png)).to eq([])
  end

  it "scan treats zbarimg exit 4 as miss" do
    allow(Open3).to receive(:capture3).and_return([ "", "", status(4) ])

    expect(PhotoZbar.scan(png)).to eq([])
  end
end
