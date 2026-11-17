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

  it "lote identify_batch in flight shows Identificando on both rows" do
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
    expect(page).to have_css("[data-lote-status]", text: "Identificando", exact_text: true, count: 2)
    expect(page).to have_no_css("#wait:not([hidden])")
  end

  it "five XMLs send identify_batch waves of 4 then 1" do
    open_lote
    record_identify_waves
    attach_file "file", wave_xmls("a.xml", "b.xml", "c.xml", "d.xml", "e.xml"), make_visible: true

    expect(page).to have_css("[data-lote-status]", text: "Pronto", count: 5)
    expect(identify_batch_sizes).to eq([ 4, 1 ])
    urls = identify_batch_posts
    expect(urls.count { |url| url.include?("/supporting_documents/identify_batch") }).to eq(2)
    expect(urls.count { |url| url.include?("/supporting_documents/identify") && !url.include?("identify_batch") }).to eq(0)
  end

  it "four XMLs send one identify_batch of 4" do
    open_lote
    record_identify_waves
    attach_file "file", wave_xmls("a.xml", "b.xml", "c.xml", "d.xml"), make_visible: true

    expect(page).to have_css("[data-lote-status]", text: "Pronto", count: 4)
    expect(identify_batch_sizes).to eq([ 4 ])
    urls = identify_batch_posts
    expect(urls.count { |url| url.include?("/supporting_documents/identify_batch") }).to eq(1)
  end

  it "five XMLs first wave in flight shows Identificando on all rows" do
    open_lote
    gate_identify_waves
    attach_file "file", wave_xmls("a.xml", "b.xml", "c.xml", "d.xml", "e.xml"), make_visible: true

    expect(page).to have_css("[data-lote-id]", count: 5)
    expect(page).to have_css("[data-lote-status]", text: "Identificando", exact_text: true, count: 4)
    expect(page).to have_css("[data-lote-status]", text: "Na fila", count: 1)
    expect(page).to have_no_css("#wait:not([hidden])")
    expect(page.evaluate_script("window.__identifyStarted")).to eq(1)
  end

  it "five XMLs first wave paints four Pronto and fifth on the next wave" do
    open_lote
    gate_identify_waves
    attach_file "file", wave_xmls("a.xml", "b.xml", "c.xml", "d.xml", "e.xml"), make_visible: true
    wait_identify_started(1)
    release_identify_wave

    expect(page).to have_css("[data-lote-status]", text: "Pronto", count: 4)
    expect(page).to have_css("[data-lote-id]", text: "e.xml")
    wait_identify_started(2)
    expect(find("[data-lote-id]", text: "e.xml")).to have_css("[data-lote-status]", text: "Identificando")
    %w[a.xml b.xml c.xml d.xml].each do |name|
      expect(find("[data-lote-id]", text: name)).to have_css("[data-lote-status]", text: "Pronto")
    end
  end

  it "five XMLs second wave paints fifth Pronto" do
    open_lote
    gate_identify_waves
    attach_file "file", wave_xmls("a.xml", "b.xml", "c.xml", "d.xml", "e.xml"), make_visible: true
    wait_identify_started(1)
    release_identify_wave
    expect(page).to have_css("[data-lote-status]", text: "Pronto", count: 4)
    wait_identify_started(2)
    release_identify_wave

    expect(page).to have_css("[data-lote-status]", text: "Pronto", count: 5)
    expect(find("[data-lote-id]", text: "e.xml")).to have_css("[data-lote-status]", text: "Pronto")
  end

  it "second picker while identifying joins later waves with one POST in flight" do
    open_lote
    gate_identify_waves
    attach_file "file", wave_xmls("a.xml", "b.xml", "c.xml", "d.xml", "e.xml"), make_visible: true
    wait_identify_started(1)
    attach_file "file", [
      xml_path("f.xml", vnf: "20.00", emit: "Emitente 6", dhemi: "2026-05-11T10:00:00-03:00", chave: lote_chave(5)),
      xml_path("g.xml", vnf: "21.00", emit: "Emitente 7", dhemi: "2026-05-11T10:00:00-03:00", chave: lote_chave(6))
    ], make_visible: true

    expect(page).to have_css("[data-lote-id]", count: 7)
    expect(page).to have_css("[data-lote-status]", text: "Identificando", exact_text: true, count: 4)
    expect(page).to have_css("[data-lote-status]", text: "Na fila", count: 3)
    expect(page.evaluate_script("window.__identifyStarted")).to eq(1)
    expect(page.evaluate_script("window.__identifyMaxInFlight")).to eq(1)
  end

  it "unreadable XML in first wave still sends the second POST" do
    open_lote
    gate_identify_waves
    files = [ write_upload("nota.xml", "<nfe/>") ] + wave_xmls("a.xml", "b.xml", "c.xml", "d.xml")
    attach_file "file", files, make_visible: true
    wait_identify_started(1)
    release_identify_wave

    expect(page).to have_content("Erro")
    expect(page).to have_content("O XML da nota fiscal não pôde ser lido")
    expect(page).to have_css("[data-lote-status]", text: "Pronto", count: 3)
    wait_identify_started(2)
    expect(find("[data-lote-id]", text: "d.xml")).to have_css("[data-lote-status]", text: "Identificando")
    expect(identify_batch_sizes).to eq([ 4, 1 ])
  end

  it "identify_batch network reject paints Erro and still sends the leftover file" do
    open_lote
    fail_fetch("/supporting_documents/identify_batch")
    record_identify_waves
    attach_file "file", wave_xmls("a.xml", "b.xml", "c.xml", "d.xml", "e.xml"), make_visible: true

    expect(page).to have_css("[data-lote-status]", text: "Erro", count: 5)
    expect(page).to have_content("O XML da nota fiscal não pôde ser lido")
    expect(identify_batch_sizes).to eq([ 4, 1 ])
  end

  it "Incluir prontos four XMLs while fifth is identifying" do
    open_lote
    gate_identify_waves
    attach_file "file", wave_xmls("a.xml", "b.xml", "c.xml", "d.xml", "e.xml"), make_visible: true
    wait_identify_started(1)
    release_identify_wave
    expect(page).to have_css("[data-lote-status]", text: "Pronto", count: 4)
    wait_identify_started(2)
    click_button "Incluir prontos (4)"

    expect(page).to have_css("#sem-mes", text: "Emitente 1")
    expect(SupportingDocument.count).to eq(4)
    expect(page).to have_content("e.xml")
    expect(page).to have_content("Identificando o arquivo…")
    expect(page).to have_css("[data-lote-id]", count: 0)
  end
end
