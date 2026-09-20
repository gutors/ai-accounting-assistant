require "rails_helper"

RSpec.describe "Served stylesheet", type: :request do
  def served_stylesheet
    get "/login"
    hrefs = Nokogiri::HTML(response.body).css('link[rel="stylesheet"]').map { |link| link["href"] }
    expect(hrefs).not_to be_empty
    hrefs.map do |href|
      get href
      expect(response).to have_http_status(:ok)
      response.body
    end.join("\n")
  end

  it "served stylesheet declares the five livro-caixa color tokens" do
    css = served_stylesheet

    {
      "paper" => "#f3f5f1",
      "ink" => "#1b3229",
      "rule" => "#c7d5ca",
      "caixa" => "#2e6b4e",
      "margem" => "#b4372a"
    }.each do |token, hex|
      expect(css).to match(/--color-#{token}:\s*#{hex}\b/i), "missing --color-#{token}: #{hex}"
    end
  end

  it "served stylesheet declares four IBM Plex font faces served from /assets/" do
    css = served_stylesheet
    faces = css.scan(/@font-face\s*\{[^}]*\}/m)

    [ [ "IBM Plex Sans", "400" ], [ "IBM Plex Sans", "500" ], [ "IBM Plex Sans", "600" ], [ "IBM Plex Mono", "400" ] ].each do |family, weight|
      face = faces.find do |block|
        block.match?(/font-family:\s*"?#{family}"?\s*;/) && block.match?(/font-weight:\s*#{weight}\s*;/)
      end
      expect(face).not_to be_nil, "missing @font-face for #{family} #{weight}"
      src = face[/url\(\s*["']?([^"')]+)["']?\s*\)/, 1]
      expect(src).to start_with("/assets/")
      expect(src).to end_with(".woff2")
    end
  end

  it "no Google Fonts host in the stylesheet or in login and home HTML" do
    css = served_stylesheet
    expect(css).not_to include("fonts.googleapis.com")
    expect(css).not_to include("fonts.gstatic.com")

    get "/login"
    expect(response.body).not_to include("fonts.googleapis.com")
    expect(response.body).not_to include("fonts.gstatic.com")

    account, organization = plant_coordinator
    sign_in_as(account, organization: organization)
    get "/"
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("fonts.googleapis.com")
    expect(response.body).not_to include("fonts.gstatic.com")
  end

  it "served stylesheet has a focus-visible outline in caixa" do
    css = served_stylesheet
    rule = css[/:focus-visible\s*\{[^}]*\}/m]

    expect(rule).not_to be_nil
    expect(rule).to match(/outline:[^;}]*var\(--color-caixa\)/)
  end

  it "served stylesheet ships no keyframes" do
    expect(served_stylesheet).not_to include("@keyframes")
  end
end
