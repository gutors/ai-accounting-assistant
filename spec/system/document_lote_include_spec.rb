require "rails_helper"

RSpec.describe "Document lote include", type: :system do
  include_context "lote system"


  it "Incluir este persists Padaria and keeps Farmácia in lote" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Padaria Central")
    find("[data-lote-id]", text: "proc-nfe-padaria.xml").click
    click_button "Incluir este"

    expect(page).to have_css("#sem-mes", text: "Padaria Central")
    expect(page).to have_css("#sem-mes", text: "R$ 155,00")
    expect(page).to have_no_css("[data-lote-id]", text: "proc-nfe-padaria.xml")
    expect(page).to have_content("proc-nfe-farmacia.xml")
    expect(page).to have_current_path("/supporting_documents")
    doc = SupportingDocument.last
    expect(doc.kind).to eq("nota_fiscal")
    expect(doc.amount_cents).to eq(15500)
    expect(doc.xml).to be_attached
    expect(doc.photo).not_to be_attached
    expect(SupportingDocument.count).to eq(1)
  end

  it "Incluir este empty Digitar persists nothing" do
    open_lote
    attach_file "file", padaria_farmacia + [ write_upload("empty.jpg", "jpeg-bytes") ], make_visible: true
    wait_pronto("Padaria Central")
    find("[data-lote-id]", text: "empty.jpg").click
    click_button "Incluir este"

    toast = find("[data-toast][data-toast-kind=error]", text: "Informe valor, data e favorecido")
    expect(toast[:class]).to include("bg-margem")
    expect(toast[:class]).to include("text-white")
    expect(toast[:class]).to include("py-3")
    expect(page).to have_content("empty.jpg")
    expect(SupportingDocument.count).to eq(0)
  end

  it "Incluir prontos twelve leaves Digitar and Erro in lote" do
    Capybara.using_wait_time(60) do
      open_lote
      payees = [
        "Padaria Central", "Mercado Bom Preço", "Farmácia São José", "Atacado Verde",
        "Gráfica Norte", "Hortifruti da Praça", "Transportes Litoral", "Copiadora Central",
        "Café do Ponto", "Oficina do Bairro", "Livraria Escolar", "Papelaria Lume"
      ]
      xmls = payees.each_with_index.map do |payee, index|
        xml_path("proc-#{index}.xml", emit: payee, chave: lote_chave(index))
      end
      digitar = write_upload("empty.jpg", "jpeg-bytes")
      erro = write_upload("nota.xml", "<nfe/>")
      attach_file "file", xmls + [ digitar, erro ], make_visible: true
      expect(page).to have_css("[data-lote-status]", text: "Pronto", count: 12)
      click_button "Incluir prontos (12)"

      expect(SupportingDocument.count).to eq(12)
      expect(page).to have_content("empty.jpg")
      expect(page).to have_content("nota.xml")
      expect(page).to have_content("Digitar")
      expect(page).to have_content("Erro")
      payees.each { |payee| expect(page).to have_content(payee) }
      sem = page.evaluate_script("document.querySelector('#sem-mes').innerText")
      expect(sem).not_to include("empty.jpg")
    end
  end

  it "batch 422 keeps every lote file" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Farmácia São José")
    page.execute_script(<<~JS)
      const el = document.querySelector("[data-controller='document-lote']")
      const ctrl = window.Stimulus.getControllerForElementAndIdentifier(el, "document-lote")
      ctrl.items[1].amount = ""
    JS
    click_button "Incluir prontos (2)"

    expect(page).to have_css("[data-notice=error]", text: "Faltam valor, data ou favorecido.")
    expect(page).to have_content("proc-nfe-padaria.xml")
    expect(page).to have_content("proc-nfe-farmacia.xml")
    expect(SupportingDocument.count).to eq(0)
  end

  it "Incluir prontos disabled while batch in flight" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Farmácia São José")
    page.execute_script(<<~JS)
      const orig = window.fetch.bind(window)
      window.fetch = (url, opts) => {
        if (String(url).includes("/supporting_documents/batch")) {
          return new Promise((resolve) => {
            window.setTimeout(() => orig(url, opts).then(resolve), 800)
          })
        }
        return orig(url, opts)
      }
    JS
    page.find("[data-lote-ready]").click
    expect(page).to have_css("[data-lote-ready][disabled]")
  end

  it "Observação typed on an XML row is saved with Incluir este" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Padaria Central")
    find("[data-lote-id]", text: "proc-nfe-padaria.xml").click
    fill_in "Observação (opcional)", with: "pago em dinheiro"
    click_button "Incluir este"

    expect(page).to have_css("#sem-mes", text: "Padaria Central")
    expect(SupportingDocument.last.observation).to eq("pago em dinheiro")
  end

  it "Incluir este double click posts the document once" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Padaria Central")
    find("[data-lote-id]", text: "proc-nfe-padaria.xml").click
    page.execute_script(<<~JS)
      window.__lotePosts = 0
      const orig = window.fetch.bind(window)
      window.fetch = (url, opts) => {
        if (String(url) === "/supporting_documents/batch" && opts && opts.method === "POST") window.__lotePosts += 1
        return orig(url, opts)
      }
    JS
    page.execute_script("document.querySelector('[data-lote-one]').click(); document.querySelector('[data-lote-one]').click()")

    expect(page).to have_no_css("[data-lote-id]", text: "proc-nfe-padaria.xml")
    expect(page.evaluate_script("window.__lotePosts")).to eq(1)
    expect(SupportingDocument.count).to eq(1)
  end

  it "batch in flight holds the page and keeps Incluir prontos disabled" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Farmácia São José")
    slow_fetch("/supporting_documents/batch", 2000)
    click_button "Incluir prontos (2)"

    expect(page).to have_css("body.is-waiting.is-waiting-copy")
    expect(page).to have_content("Incluindo documentos…")
    expect(page).to have_css("#wait:not([hidden])")
    expect(page).to have_css("[data-lote-ready][disabled]")
  end

  it "Incluir este in flight does not hold the page and leaves the other row editable" do
    open_lote
    attach_file "file", padaria_farmacia + [ write_upload("empty.jpg", "jpeg-bytes") ], make_visible: true
    wait_pronto("Farmácia São José")
    find("[data-lote-id]", text: "proc-nfe-padaria.xml").click
    page.execute_script(<<~JS)
      const orig = window.fetch.bind(window)
      window.fetch = (url, opts) => {
        if (String(url) === "/supporting_documents/batch" && opts && opts.method === "POST") {
          return new Promise((resolve) => {
            window.setTimeout(() => orig(url, opts).then(resolve), 2000)
          })
        }
        return orig(url, opts)
      }
    JS
    click_button "Incluir este"

    expect(page).to have_no_css("body.is-waiting")
    expect(page).to have_no_css("#wait:not([hidden])")
    expect(page).to have_css("[data-toast][data-toast-kind=progress]", text: "Incluindo documento…")
    expect(find("[data-toast]")[:class]).to include("bg-caixa")
    find("[data-lote-id]", text: "empty.jpg").click
    find_field("amount").set("10,00")
    find_field("date").set("2026-05-10")
    find_field("payee").set("Mercado Bom Preço")
    expect(find("[data-lote-id]", text: "empty.jpg")).to have_css("[data-lote-status]", text: "Pronto")
    expect(page).to have_field("amount", with: "10,00")
  end

  it "Digitar row stays in lote after prontos batch completes" do
    open_lote
    attach_file "file", padaria_farmacia + [ write_upload("empty.jpg", "jpeg-bytes") ], make_visible: true
    wait_pronto("Farmácia São José")
    click_button "Incluir prontos (2)"

    expect(page).to have_css("section[data-controller=document-lote] h2", exact_text: "Incluir documento")
    expect(page).to have_content("empty.jpg")
    expect(page).to have_button("Incluir documento")
    expect_no_situacao_sheet
    expect(SupportingDocument.count).to eq(2)
  end

  it "Incluir prontos is enabled again when the batch fails at the network level" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Farmácia São José")
    fail_fetch("/supporting_documents/batch")
    click_button "Incluir prontos (2)"

    expect(page).to have_css("[data-lote-id]", count: 2)
    expect(page).to have_button("Incluir prontos (2)", disabled: false)
    expect(SupportingDocument.count).to eq(0)
  end

  def record_lote_kinds
    page.execute_script(<<~JS)
      window.__loteKinds = []
      const orig = window.fetch.bind(window)
      window.fetch = (url, opts) => {
        if (String(url).startsWith("/supporting_documents") && opts && opts.method === "POST") {
          window.__loteKinds.push(opts.body.getAll("kind").concat(opts.body.getAll("documents[][kind]")))
        }
        return orig(url, opts)
      }
    JS
  end

  it "Incluir este sends the photo row kind it showed" do
    open_lote
    attach_file "file", write_upload("empty.jpg", "jpeg-bytes"), make_visible: true
    expect(page).to have_field("kind", with: "Recibo", readonly: true)
    record_lote_kinds
    find_field("amount").set("10,00")
    find_field("date").set("2026-05-10")
    find_field("payee").set("Mercado Bom Preço")
    click_button "Incluir documento"

    expect(page).to have_css("section[data-controller=document-lote] h2", exact_text: "Incluir documentos")
    expect(page.evaluate_script("window.__loteKinds")).to eq([ [ "recibo" ] ])
    expect(SupportingDocument.find_by!(payee: "Mercado Bom Preço").kind).to eq("recibo")
  end

  it "Incluir prontos sends the kind of every row it includes" do
    open_lote
    attach_file "file", padaria_farmacia + [ write_upload("empty.jpg", "jpeg-bytes") ], make_visible: true
    wait_pronto("Farmácia São José")
    find("[data-lote-id]", text: "empty.jpg").click
    find_field("amount").set("10,00")
    find_field("date").set("2026-05-10")
    find_field("payee").set("Mercado Bom Preço")
    record_lote_kinds
    click_button "Incluir prontos (3)"

    expect(page).to have_no_css("[data-lote-id]")
    expect(page.evaluate_script("window.__loteKinds")).to eq([ [ "nota_fiscal", "nota_fiscal", "recibo" ] ])
  end

  def record_lote_chaves
    page.execute_script(<<~JS)
      window.__loteChaves = []
      const orig = window.fetch.bind(window)
      window.fetch = (url, opts) => {
        if (String(url).startsWith("/supporting_documents") && opts && opts.method === "POST") {
          window.__loteChaves.push({
            chave: opts.body.getAll("chave"),
            documents: opts.body.getAll("documents[][chave]")
          })
        }
        return orig(url, opts)
      }
    JS
  end

  it "Incluir prontos posts documents chave from identified XML" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Farmácia São José")
    record_lote_chaves
    click_button "Incluir prontos (2)"

    expect(page).to have_css("#sem-mes", text: "Padaria Central")
    posted = page.evaluate_script("window.__loteChaves")
    expect(posted.first["chave"]).to eq([])
    expect(posted.first["documents"]).to include(lote_chave(0))
  end

  it "Incluir este posts chave from identified XML" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Farmácia São José")
    find("[data-lote-id]", text: "proc-nfe-padaria.xml").click
    record_lote_chaves
    click_button "Incluir este"

    expect(page).to have_css("#sem-mes", text: "Padaria Central")
    posted = page.evaluate_script("window.__loteChaves")
    expect(posted.first["chave"]).to eq([])
    expect(posted.first["documents"]).to eq([ lote_chave(0) ])
  end

  it "Incluir prontos recibo FormData has no chave" do
    open_lote
    attach_file "file", write_upload("empty.jpg", "jpeg-bytes"), make_visible: true
    expect(page).to have_field("kind", with: "Recibo", readonly: true)
    find_field("amount").set("10,00")
    find_field("date").set("2026-05-10")
    find_field("payee").set("Mercado Bom Preço")
    record_lote_chaves
    click_button "Incluir documento"

    expect(page).to have_css("#sem-mes", text: "Mercado Bom Preço")
    posted = page.evaluate_script("window.__loteChaves")
    expect(posted.first["chave"]).to eq([])
    expect(posted.first["documents"].all?(&:blank?)).to be(true)
    expect(SupportingDocument.find_by!(payee: "Mercado Bom Preço").chave).to be_nil
  end

  it "select Digitar fills typed book and secondary toolbar" do
    open_lote
    attach_file "file", [
      write_upload("empty.jpg", "jpeg-bytes"),
      write_upload("other.jpg", "jpeg-other")
    ], make_visible: true
    expect(page).to have_content("Digitar")
    find("[data-lote-id]", text: "empty.jpg").click

    expect(page).not_to have_css("#arquivo")
    expect(find_field("kind", readonly: true).value).to eq("Recibo")
    expect(find_field("amount").value).to eq("")
    expect(find_field("date").value).to eq("")
    expect(find_field("payee").value).to eq("")
    %w[amount date payee].each { |field| expect(page).to have_css("[data-origin=#{field}]", text: "Digitado") }
    expect(page).to have_button("Incluir prontos (0)")
    expect(page).to have_field("Observação (opcional)")
    one = find("[data-lote-one]")
    expect(one[:class]).to include("ds-btn-secondary")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-lote-one]')).paddingTop")).to eq("8px")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-lote-one]')).paddingLeft")).to eq("16px")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-lote-one]')).backgroundColor")).to eq("rgba(0, 0, 0, 0)")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-lote-one]')).borderTopColor")).to include("27, 50, 41")
    retirar = find("[data-lote-remove]")
    expect(retirar[:class]).to include("ds-btn-secondary")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-lote-remove]')).color")).to include("180, 55, 42")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-lote-remove]')).borderTopColor")).to include("180, 55, 42")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-lote-remove]')).paddingTop")).to eq("8px")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-lote-remove]')).paddingLeft")).to eq("16px")
  end

  it "coordinator lote arrangement matches batch-select mock" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Padaria Central")
    expect(page).to have_field("Observação (opcional)")
    expect(page).not_to have_css("#arquivo")
    expect(page).to have_css("[data-document-lote-target=editor] > div:nth-child(1) [data-document-lote-target=proof] [data-document-lote-target=caption]")
    expect(page).to have_css("[data-document-lote-target=editor] > [data-document-lote-target=toolbar]")
    expect(page).to have_css("[data-document-lote-target=editor] > [data-document-lote-target=sheet]")
    labels = page.all("[data-lote-ready], [data-lote-one], [data-lote-remove]").map(&:text)
    expect(labels[0]).to start_with("Incluir prontos")
    expect(labels[1]).to eq("Incluir este")
    expect(labels[2]).to eq("Retirar")
    sem_top = page.evaluate_script("document.querySelector('#sem-mes').getBoundingClientRect().top")
    sheet_top = page.evaluate_script("document.querySelector('[data-document-lote-target=sheet]').getBoundingClientRect().top")
    expect(sheet_top).to be < sem_top
  end

  it "a zero Valor keeps a Digitar row out of Pronto" do
    open_lote
    attach_file "file", [
      write_upload("empty.jpg", "jpeg-bytes"),
      write_upload("other.jpg", "jpeg-other")
    ], make_visible: true
    find("[data-lote-id]", text: "empty.jpg").click
    find_field("amount").set("10,00")
    find_field("date").set("2026-05-10")
    find_field("payee").set("Mercado Bom Preço")
    expect(find("[data-lote-id]", text: "empty.jpg")).to have_css("[data-lote-status]", text: "Pronto")

    find_field("amount").set("0,00")

    expect(find("[data-lote-id]", text: "empty.jpg")).to have_css("[data-lote-status]", text: "Digitar")
    expect(page).to have_button("Incluir prontos (0)")
  end
end
