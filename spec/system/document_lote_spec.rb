require "rails_helper"

RSpec.describe "Document lote", type: :system do
  include_context "lote system"

  it "coordinator identify two XMLs fills lote without persisting" do
    open_lote
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
    %w[Data Favorecido Tipo Valor Situação].each { |head| expect(page).to have_content(head) }
  end

  it "coordinator photo miss lote row is Digitar Recibo" do
    open_lote
    attach_file "file", [
      write_upload("empty.jpg", "jpeg-bytes"),
      write_upload("other.jpg", "jpeg-other")
    ], make_visible: true

    expect(page).to have_content("Digitar")
    expect(page).to have_content("Recibo")
    expect(page).to have_css("[data-lote-id]", text: "—")
    find("[data-lote-id]", text: "empty.jpg").click
    expect(page).to have_css("[data-origin=amount]", text: "Digitado")
    expect(SupportingDocument.count).to eq(0)
  end

  it "coordinator unreadable XML is Erro and leaves other lote rows" do
    open_lote
    good = xml_path("proc-nfe-padaria.xml", chave: lote_chave(0))
    bad = write_upload("nota.xml", "<nfe/>")
    attach_file "file", [ good, bad ], make_visible: true

    expect(page).to have_content("proc-nfe-padaria.xml")
    expect(page).to have_content("Pronto")
    expect(page).to have_content("Erro")
    expect(page).to have_content("O XML da nota fiscal não pôde ser lido")
    expect(SupportingDocument.count).to eq(0)
  end

  it "lote identify in flight shows Identificando o arquivo" do
    open_lote
    page.execute_script(<<~JS)
      const orig = window.fetch.bind(window)
      window.fetch = (url, opts) => {
        if (String(url).includes("/supporting_documents/identify")) {
          return new Promise((resolve) => {
            window.setTimeout(() => orig(url, opts).then(resolve), 800)
          })
        }
        return orig(url, opts)
      }
    JS
    attach_file "file", write_upload("danfe-mercado.jpg", "jpeg-bytes"), make_visible: true

    expect(page).to have_content("Identificando o arquivo…")
    expect(page).to have_no_css("body.is-waiting")
    expect(page).to have_no_css("#wait:not([hidden])")
  end

  it "one XML is simple include chrome" do
    open_lote
    attach_file "file", xml_path("proc-nfe-padaria.xml", vnf: "155.00", emit: "Padaria Central", dhemi: "2026-05-11T10:00:00-03:00", chave: lote_chave(0)), make_visible: true
    wait_one_xml

    expect(page).to have_css("section[data-controller=document-lote] h2", exact_text: "Incluir documento")
    expect_no_situacao_sheet
    expect(page).to have_no_button("Incluir este")
    expect(page).to have_no_button("Retirar")
    expect(find("[data-document-lote-target=proof]")).to have_button("Limpar")
    primary = find("[data-lote-one]")
    expect(primary.text).to eq("Incluir documento")
    expect(primary[:class]).to include("ds-btn-primary")
    style = page.evaluate_script(<<~JS)
      (function() {
        var s = getComputedStyle(document.querySelector("[data-lote-one]"))
        return { padT: s.paddingTop, padL: s.paddingLeft, bg: s.backgroundColor, color: s.color }
      })()
    JS
    expect(style["padT"]).to eq("8px")
    expect(style["padL"]).to eq("16px")
    expect(style["bg"]).to include("46, 107, 78")
    expect(style["color"]).to include("255, 255, 255")
  end

  it "Incluir documento one XML persists Padaria and empty drop" do
    open_lote
    attach_file "file", xml_path("proc-nfe-padaria.xml", vnf: "155.00", emit: "Padaria Central", dhemi: "2026-05-11T10:00:00-03:00", chave: lote_chave(0)), make_visible: true
    wait_one_xml
    click_button "Incluir documento"

    expect(page).to have_css("#sem-mes", text: "Padaria Central")
    expect(page).to have_css("#sem-mes", text: "R$ 155,00")
    expect(page).to have_css("section[data-controller=document-lote] h2", exact_text: "Incluir documentos")
    expect(page).to have_css("[data-document-lote-target=drop]", visible: true)
    expect(page).to have_current_path("/supporting_documents")
    doc = SupportingDocument.last
    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.amount_cents).to eq(15500)
    expect(doc.xml).to be_attached
    expect(doc.photo).not_to be_attached
    expect(SupportingDocument.count).to eq(1)
  end

  it "Limpar one XML returns empty drop" do
    open_lote
    attach_file "file", xml_path("proc-nfe-padaria.xml", vnf: "155.00", emit: "Padaria Central", dhemi: "2026-05-11T10:00:00-03:00", chave: lote_chave(0)), make_visible: true
    wait_one_xml
    find("[data-document-lote-target=proof]").click_button("Limpar")

    expect(SupportingDocument.count).to eq(0)
    expect(page).to have_css("section[data-controller=document-lote] h2", exact_text: "Incluir documentos")
    expect(page).to have_css("[data-document-lote-target=drop]", visible: true)
    expect(page).to have_no_button("Limpar")
  end

  it "Incluir documento empty Digitar persists nothing" do
    open_lote
    attach_file "file", write_upload("empty.jpg", "jpeg-bytes"), make_visible: true
    expect(page).to have_button("Incluir documento")
    click_button "Incluir documento"

    expect(page).to have_css("[data-toast][data-toast-kind=error]", text: "Informe valor, data e favorecido")
    expect(SupportingDocument.count).to eq(0)
  end

  it "second XML opens lote chrome" do
    open_lote
    attach_file "file", xml_path("proc-nfe-padaria.xml", vnf: "155.00", emit: "Padaria Central", dhemi: "2026-05-11T10:00:00-03:00", chave: lote_chave(0)), make_visible: true
    wait_one_xml
    attach_file "file", xml_path("proc-nfe-farmacia.xml", vnf: "89.40", emit: "Farmácia São José", dhemi: "2026-05-03T10:00:00-03:00", chave: lote_chave(1)), make_visible: true
    wait_pronto("Farmácia São José")

    expect(page).to have_css("section[data-controller=document-lote] h2", exact_text: "Incluir documentos")
    %w[Data Favorecido Tipo Valor Situação].each { |head| expect(page).to have_css(".lote-head", text: head) }
    expect(page).to have_css("[data-lote-id]", text: "proc-nfe-padaria.xml")
    expect(page).to have_css("[data-lote-id]", text: "proc-nfe-farmacia.xml")
    labels = page.all("[data-lote-ready], [data-lote-one], [data-lote-remove]").map(&:text)
    expect(labels[0]).to start_with("Incluir prontos (")
    expect(labels[0]).to end_with(")")
    expect(labels[1]).to eq("Incluir este")
    expect(labels[2]).to eq("Retirar")
    expect(find("[data-lote-ready]")[:class]).to include("ds-btn-primary")
    expect(find("[data-lote-one]")[:class]).to include("ds-btn-secondary")
    expect(find("[data-lote-remove]")[:class]).to include("ds-btn-secondary")
    expect(find("[data-document-lote-target=proof]")).to have_no_button("Limpar")
  end

  it "Retirar down to one restores simple include" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Farmácia São José")
    find("[data-lote-id]", text: "proc-nfe-farmacia.xml").click
    click_button "Retirar"

    expect(page).to have_css("section[data-controller=document-lote] h2", exact_text: "Incluir documento")
    expect_no_situacao_sheet
    expect(find("[data-document-lote-target=proof]")).to have_button("Limpar")
    expect(page).to have_button("Incluir documento")
  end

  it "one file identify in flight has no Situacao sheet" do
    open_lote
    page.execute_script(<<~JS)
      const orig = window.fetch.bind(window)
      window.fetch = (url, opts) => {
        if (String(url).includes("/supporting_documents/identify")) {
          return new Promise((resolve) => {
            window.setTimeout(() => orig(url, opts).then(resolve), 800)
          })
        }
        return orig(url, opts)
      }
    JS
    attach_file "file", write_upload("danfe-mercado.jpg", "jpeg-bytes"), make_visible: true

    expect(page).to have_content("Identificando o arquivo…")
    expect_no_situacao_sheet
    expect(SupportingDocument.count).to eq(0)
  end

  it "one unreadable XML has Limpar and no Situacao sheet" do
    open_lote
    attach_file "file", write_upload("nota.xml", "<nfe/>"), make_visible: true

    expect(SupportingDocument.count).to eq(0)
    expect(page).to have_css("[data-notice=error], [data-toast]", text: /O XML da nota fiscal não pôde ser lido/)
    expect_no_situacao_sheet
    expect(find("[data-document-lote-target=proof]")).to have_button("Limpar")
  end

  it "one jpg caption is FOTO filename under image" do
    open_lote
    attach_file "file", write_upload("empty.jpg", "jpeg-bytes"), make_visible: true
    expect(page).to have_css("[data-document-lote-target=caption] strong", text: "FOTO")

    proof = find("[data-document-lote-target=proof]")
    expect(proof).to have_no_css("label[for=arquivo]")
    expect(page).not_to have_css("#arquivo")
    caption = proof.find("[data-document-lote-target=caption]")
    expect(caption.find("strong").text).to eq("FOTO")
    expect(caption.text).to eq("FOTO - empty.jpg")
    weight = page.evaluate_script("getComputedStyle(document.querySelector('[data-document-lote-target=caption] strong')).fontWeight")
    expect(weight).to eq("600")
    under = page.evaluate_script(<<~JS)
      (function() {
        var proof = document.querySelector("[data-document-lote-target=proof]")
        var img = proof.querySelector("img")
        var caption = proof.querySelector("[data-document-lote-target=caption]")
        return !!(img.compareDocumentPosition(caption) & Node.DOCUMENT_POSITION_FOLLOWING)
      })()
    JS
    expect(under).to eq(true)
    expect(proof.text).not_to include("sem leitura nesta versão")
    expect(proof.all("p").map { |node| node.text.strip }).not_to include("Recibo")
    expect(proof.all("p").map { |node| node.text.strip }).not_to include("Nota fiscal")
  end

  it "one XML caption is XML filename" do
    open_lote
    attach_file "file", xml_path("proc-nfe-padaria.xml", vnf: "155.00", emit: "Padaria Central", dhemi: "2026-05-11T10:00:00-03:00", chave: lote_chave(0)), make_visible: true
    wait_one_xml

    caption = find("[data-document-lote-target=caption]")
    expect(caption.find("strong").text).to eq("XML")
    expect(caption.text).to eq("XML - proc-nfe-padaria.xml")
    weight = page.evaluate_script("getComputedStyle(document.querySelector('[data-document-lote-target=caption] strong')).fontWeight")
    expect(weight).to eq("600")
    expect(page).not_to have_css("#arquivo")
  end

  it "lote selected Padaria caption is XML filename" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Farmácia São José")
    find("[data-lote-id]", text: "proc-nfe-padaria.xml").click

    expect(page).to have_css('[aria-selected="true"]', text: "proc-nfe-padaria.xml")
    caption = find("[data-document-lote-target=caption]")
    expect(caption.find("strong").text).to eq("XML")
    expect(caption.text).to eq("XML - proc-nfe-padaria.xml")
    expect(page).not_to have_css("[data-document-lote-target=proof] img", visible: true)
  end

  it "one XML Tipo is readonly input then chave" do
    open_lote
    attach_file "file", xml_path("proc-nfe-padaria.xml", vnf: "155.00", emit: "Padaria Central", dhemi: "2026-05-11T10:00:00-03:00", chave: lote_chave(0)), make_visible: true
    wait_one_xml

    expect(page.find("label[for=kind]").text).to eq("Tipo")
    kind = find_field("kind")
    expect(kind.value).to eq("Nota fiscal")
    expect(kind[:readonly]).to be_present
    expect(kind.disabled?).to eq(false)
    expect(page).not_to have_css("select#kind", visible: true)
    next_id = page.evaluate_script(<<~JS)
      (function() {
        var kind = document.querySelector("#kind")
        var named = Array.prototype.slice.call(document.querySelectorAll("input[name], select[name], textarea[name]"))
        var after = named.filter(function(el) { return kind.compareDocumentPosition(el) & Node.DOCUMENT_POSITION_FOLLOWING })
        return after[0] ? after[0].id : null
      })()
    JS
    expect(next_id).to eq("chave")
  end

  it "one jpg Tipo is readonly Recibo and hides chave" do
    open_lote
    attach_file "file", write_upload("empty.jpg", "jpeg-bytes"), make_visible: true

    kind = find_field("kind")
    expect(kind.value).to eq("Recibo")
    expect(kind[:readonly]).to be_present
    expect(find_field("amount").value).to eq("")
    expect(find_field("date").value).to eq("")
    expect(find_field("payee").value).to eq("")
    %w[amount date payee].each { |field| expect(page).to have_css("[data-origin=#{field}]", text: "Digitado") }
    expect(page).not_to have_css("#chave", visible: true)
  end

  it "31st file is not added to the lote" do
    open_lote
    paths = (1..31).map { |n| write_upload("f#{n}.jpg", "jpeg-#{n}") }
    attach_file "file", paths, make_visible: true

    expect(page).to have_css("[data-notice=error]", text: "No máximo 30 arquivos neste lote")
    expect(page).to have_css("[data-lote-id]", count: 30)
  end

  it "select Padaria fills compact book from XML" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Padaria Central")
    find("[data-lote-id]", text: "proc-nfe-padaria.xml").click

    expect(page).to have_css('[aria-selected="true"]', text: "proc-nfe-padaria.xml")
    expect(page).to have_css("[data-document-lote-target=proof]", text: "proc-nfe-padaria.xml")
    expect(page).not_to have_css("#arquivo")
    expect(find_field("kind", readonly: true).value).to eq("Nota fiscal")
    expect(find_field("amount", disabled: true).value).to eq("155,00")
    expect(find_field("date", disabled: true).value).to eq("2026-05-11")
    expect(find_field("payee", disabled: true).value).to eq("Padaria Central")
    %w[amount date payee].each { |field| expect(page).to have_css("[data-origin=#{field}]", text: "XML autorizado") }
    cols = page.evaluate_script("getComputedStyle(document.querySelector('[data-document-lote-target=pair]')).gridTemplateColumns")
    expect(cols.split.length).to eq(2)
  end


  it "Retirar drops Padaria without confirm" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Padaria Central")
    find("[data-lote-id]", text: "proc-nfe-padaria.xml").click
    expect(page).not_to have_css("[data-turbo-confirm]")
    click_button "Retirar"

    expect(page).not_to have_content("proc-nfe-padaria.xml")
    expect(page).to have_content("proc-nfe-farmacia.xml")
    expect(SupportingDocument.count).to eq(0)
  end

  it "Incluir prontos two XMLs empties lote into Sem mes" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Farmácia São José")
    click_button "Incluir prontos (2)"

    expect(page).to have_css("#sem-mes", text: "Padaria Central")
    expect(page).to have_css("#sem-mes", text: "Farmácia São José")
    expect(page).to have_css("#sem-mes", text: "R$ 155,00")
    expect(page).to have_css("#sem-mes", text: "R$ 89,40")
    expect(page).to have_no_css("[data-lote-status]")
    expect(SupportingDocument.count).to eq(2)
  end


  it "select Padaria chave sits under Tipo" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Padaria Central")
    find("[data-lote-id]", text: "proc-nfe-padaria.xml").click

    expect(page.find("label[for=chave]").text).to eq("Chave de acesso (opcional)")
    chave = find_field("chave", disabled: true)
    expect(chave.value).to eq(lote_chave(0))
    expect(chave[:class]).to include("font-mono")
    next_id = page.evaluate_script(<<~JS)
      (function() {
        var kind = document.querySelector("#kind")
        var named = Array.prototype.slice.call(document.querySelectorAll("input[name], select[name], textarea[name]"))
        var after = named.filter(function(el) { return kind.compareDocumentPosition(el) & Node.DOCUMENT_POSITION_FOLLOWING })
        return after[0] ? after[0].id : null
      })()
    JS
    expect(next_id).to eq("chave")
  end

  it "select Digitar Recibo hides chave" do
    open_lote
    attach_file "file", write_upload("empty.jpg", "jpeg-bytes"), make_visible: true
    expect(page).to have_field("kind", with: "Recibo", readonly: true)

    expect(find_field("kind", readonly: true).value).to eq("Recibo")
    expect(page).not_to have_css("#chave", visible: true)
    expect(page.find("#chave", visible: :hidden).disabled?).to be(true)
  end

  it "selected jpg proof is blob img" do
    open_lote
    attach_file "file", write_upload("empty.jpg", "jpeg-bytes"), make_visible: true
    expect(page).to have_css("[data-document-lote-target=caption]", text: "empty.jpg")

    img = find("[data-document-lote-target=proof] img", visible: true)
    expect(img[:alt]).to eq("empty.jpg")
    expect(img[:src]).to start_with("blob:")
  end

  it "selected XML proof img is not visible" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Padaria Central")
    find("[data-lote-id]", text: "proc-nfe-padaria.xml").click

    expect(page).not_to have_css("[data-document-lote-target=proof] img", visible: true)
  end

  it "selected pdf proof is blob embed" do
    open_lote
    attach_file "file", write_upload("danfe.pdf", "%PDF-1.1"), make_visible: true
    expect(page).to have_css("[data-document-lote-target=caption]", text: "danfe.pdf")

    embed = find("[data-document-lote-target=proof] embed[type='application/pdf']", visible: true)
    expect(embed[:src]).to start_with("blob:")
  end

  it "Retirar jpg leaves XML proof without img" do
    open_lote
    attach_file "file", padaria_farmacia + [ write_upload("empty.jpg", "jpeg-bytes") ], make_visible: true
    wait_pronto("Padaria Central")
    find("[data-lote-id]", text: "empty.jpg").click
    expect(page).to have_css("[data-document-lote-target=proof] img", visible: true)
    click_button "Retirar"

    expect(page).to have_no_content("empty.jpg")
    expect(page).to have_css("[data-lote-id]", text: "proc-nfe-padaria.xml")
    expect(page).not_to have_css("[data-document-lote-target=proof] img", visible: true)
  end
end
