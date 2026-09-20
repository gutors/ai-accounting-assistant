require "rails_helper"

RSpec.describe "App mark" do
  it "icon.svg is the ledger mark" do
    svg = Rails.root.join("public/icon.svg").read
    rects = Nokogiri::XML(svg).css("rect")

    expect(svg).not_to include('fill="red"')
    expect(rects.map { |rect| rect["fill"] }).to include("#2e6b4e", "#b4372a")
  end
end
