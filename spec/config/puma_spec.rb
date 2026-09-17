require "rails_helper"

RSpec.describe "Puma config" do
  it "worker_timeout is 300" do
    expect(Rails.root.join("config/puma.rb").read).to match(/worker_timeout\s+300/)
  end
end
