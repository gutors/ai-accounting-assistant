require "rails_helper"

RSpec.describe "View palette" do
  it "views use token utilities and no raw Tailwind palette" do
    offenders = Rails.root.glob("app/views/**/*").select(&:file?).filter_map do |path|
      match = path.read.match(/\b(zinc|gray|slate|neutral|stone)-/)
      "#{path.relative_path_from(Rails.root)}: #{match[0]}" if match
    end

    expect(offenders).to be_empty
  end
end
