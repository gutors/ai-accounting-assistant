require "rails_helper"

RSpec.describe "Document lote identify_batch", type: :system do
  include_context "lote system"

  it "coordinator identify two XMLs fills lote without persisting" do
    open_lote
    page.execute_script(<<~JS)
      window.__identifyPosts = []
      const orig = window.fetch.bind(window)
      window.fetch = (url, opts) => {
        window.__identifyPosts.push(String(url))
        return orig(url, opts)
      }
    JS
    attach_file "file", padaria_farmacia, make_visible: true

    expect(page).to have_content("Situação")
    expect(page).to have_content("proc-nfe-padaria.xml")
    expect(page).to have_content("proc-nfe-farmacia.xml")
    expect(page).to have_content("Padaria Central")
    expect(page).to have_content("Farmácia São José")
    expect(page).to have_content("R$ 155,00")
    expect(page).to have_content("R$ 89,40")
    expect(page).to have_css("[data-lote-status]", text: "Pronto", count: 2)
    expect(page).to have_content("Nenhum documento")
    expect(SupportingDocument.count).to eq(0)
    urls = page.evaluate_script("window.__identifyPosts")
    expect(urls.count { |url| url.include?("/supporting_documents/identify_batch") }).to eq(1)
    expect(urls.count { |url| url.include?("/supporting_documents/identify") && !url.include?("identify_batch") }).to eq(0)
  end

  it "lote identify_batch in flight shows Identificando o arquivo on both rows" do
    open_lote
    page.execute_script(<<~JS)
      const orig = window.fetch.bind(window)
      window.fetch = (url, opts) => {
        if (String(url).includes("/supporting_documents/identify_batch")) {
          return new Promise((resolve) => {
            window.setTimeout(() => orig(url, opts).then(resolve), 800)
          })
        }
        return orig(url, opts)
      }
    JS
    attach_file "file", padaria_farmacia, make_visible: true

    expect(page).to have_css("[data-lote-id]", count: 2)
    expect(page).to have_css("[data-lote-status]", text: "Identificando o arquivo…", count: 2)
    expect(page).to have_no_css("#wait:not([hidden])")
  end
end
