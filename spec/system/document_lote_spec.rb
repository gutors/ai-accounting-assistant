require "rails_helper"
require "capybara/cuprite"

RSpec.describe "Document lote", type: :system do
  before do
    driven_by :cuprite, screen_size: [ 1280, 900 ], options: {
      browser_options: { "no-sandbox": nil },
      process_timeout: 30,
      timeout: 20
    }
  end

  def sign_in_through_google(account)
    stub_google_oauth(email: account.email, uid: account.google_uid)
    visit "/auth/google_oauth2/callback"
    expect(page).to have_css("header nav")
  end

  def write_upload(name, content)
    path = Rails.root.join("tmp", name)
    FileUtils.mkdir_p(path.dirname)
    File.binwrite(path, content)
    path
  end

  def lote_chave(index)
    "4326051122233300018155001000000001112345#{(6780 + index).to_s.rjust(4, "0")}"
  end

  def xml_path(name, **attrs)
    write_upload(name, authorized_nfe_xml(**attrs))
  end

  def open_lote
    account, _organization = plant_coordinator
    sign_in_through_google(account)
    visit "/supporting_documents"
  end

  def padaria_farmacia
    [
      xml_path("proc-nfe-padaria.xml", vnf: "155.00", emit: "Padaria Central", dhemi: "2026-05-11T10:00:00-03:00", chave: lote_chave(0)),
      xml_path("proc-nfe-farmacia.xml", vnf: "89.40", emit: "Farmácia São José", dhemi: "2026-05-03T10:00:00-03:00", chave: lote_chave(1))
    ]
  end

  def wait_pronto(text)
    expect(page).to have_css("[data-lote-status]", text: "Pronto")
    expect(page).to have_content(text)
  end

  def slow_fetch(path, ms)
    page.execute_script(<<~JS)
      const orig = window.fetch.bind(window)
      window.fetch = (url, opts) => {
        if (String(url).includes(#{path.to_json})) {
          return new Promise((resolve) => {
            window.setTimeout(() => orig(url, opts).then(resolve), #{ms})
          })
        }
        return orig(url, opts)
      }
    JS
  end

  def fail_fetch(path)
    page.execute_script(<<~JS)
      const orig = window.fetch.bind(window)
      window.fetch = (url, opts) => {
        if (String(url).includes(#{path.to_json})) return Promise.reject(new TypeError("Failed to fetch"))
        return orig(url, opts)
      }
    JS
  end

  # A batch response re-renders the lote sheet and toolbar. Poll in JS (no node
  # handles) until that re-render has landed, so DOM-count matchers do not race it.
  def wait_for_lote_settled(rows:, ready_count:)
    script = <<~JS
      (() => {
        const ready = document.querySelector("[data-lote-ready]")
        return document.querySelectorAll("[data-lote-id]").length === #{rows} &&
          !!ready && !ready.disabled && ready.textContent.includes("(#{ready_count})")
      })()
    JS
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + Capybara.default_max_wait_time
    until page.evaluate_script(script)
      raise "lote did not settle to #{rows} row(s)" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      sleep 0.05
    end
  end

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
    attach_file "file", write_upload("empty.jpg", "jpeg-bytes"), make_visible: true

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
    expect(find("[data-document-lote-target=proof]").find_field("arquivo", disabled: true).value).to eq("XML")
    expect(page).not_to have_css("[data-document-lote-target=book] #arquivo")
    expect(page).to have_select("kind", selected: "Nota fiscal", disabled: true)
    expect(find_field("amount", disabled: true).value).to eq("155,00")
    expect(find_field("date", disabled: true).value).to eq("2026-05-11")
    expect(find_field("payee", disabled: true).value).to eq("Padaria Central")
    %w[amount date payee].each { |field| expect(page).to have_css("[data-origin=#{field}]", text: "XML autorizado") }
    cols = page.evaluate_script("getComputedStyle(document.querySelector('[data-document-lote-target=pair]')).gridTemplateColumns")
    expect(cols.split.length).to eq(2)
  end

  it "select Digitar fills typed book and secondary toolbar" do
    open_lote
    attach_file "file", write_upload("empty.jpg", "jpeg-bytes"), make_visible: true
    expect(page).to have_content("Digitar")
    find("[data-lote-id]", text: "empty.jpg").click

    expect(find("[data-document-lote-target=proof]").find_field("arquivo", disabled: true).value).to eq("Foto")
    expect(page).to have_select("kind", selected: "Recibo", disabled: true)
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
    attach_file "file", write_upload("empty.jpg", "jpeg-bytes"), make_visible: true
    expect(page).to have_content("Digitar")
    find("[data-lote-id]", text: "empty.jpg").click
    click_button "Incluir este"

    expect(SupportingDocument.count).to eq(0)
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

  it "coordinator lote arrangement matches batch-select mock" do
    open_lote
    attach_file "file", padaria_farmacia, make_visible: true
    wait_pronto("Padaria Central")
    expect(page).to have_field("Observação (opcional)")
    expect(page).to have_css("[data-document-lote-target=editor] > div:nth-child(1) [data-document-lote-target=proof] #arquivo")
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
        if (String(url) === "/supporting_documents" && opts && opts.method === "POST") window.__lotePosts += 1
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

  it "Digitar row stays in lote after prontos batch completes" do
    open_lote
    attach_file "file", padaria_farmacia + [ write_upload("empty.jpg", "jpeg-bytes") ], make_visible: true
    wait_pronto("Farmácia São José")
    click_button "Incluir prontos (2)"

    wait_for_lote_settled(rows: 1, ready_count: 0)
    expect(page).to have_css("[data-lote-id]", count: 1)
    expect(page).to have_content("empty.jpg")
    expect(page).to have_button("Incluir prontos (0)", disabled: false)
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
    expect(page).to have_css("[data-lote-status]", text: "Digitar")
    find("[data-lote-id]", text: "empty.jpg").click
    record_lote_kinds
    find_field("amount").set("10,00")
    find_field("date").set("2026-05-10")
    find_field("payee").set("Mercado Bom Preço")
    click_button "Incluir este"

    expect(page).to have_no_css("[data-lote-id]")
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
    expect(posted.first["documents"]).to eq([])
    expect(posted.first["chave"]).to eq([ lote_chave(0) ])
  end

  it "Incluir prontos recibo FormData has no chave" do
    open_lote
    attach_file "file", write_upload("empty.jpg", "jpeg-bytes"), make_visible: true
    expect(page).to have_css("[data-lote-status]", text: "Digitar")
    find("[data-lote-id]", text: "empty.jpg").click
    find_field("amount").set("10,00")
    find_field("date").set("2026-05-10")
    find_field("payee").set("Mercado Bom Preço")
    expect(page).to have_css("[data-lote-status]", text: "Pronto")
    record_lote_chaves
    click_button "Incluir prontos (1)"

    expect(page).to have_no_css("[data-lote-id]")
    posted = page.evaluate_script("window.__loteChaves")
    expect(posted.first["chave"]).to eq([])
    expect(posted.first["documents"].all?(&:blank?)).to be(true)
    expect(SupportingDocument.find_by!(payee: "Mercado Bom Preço").chave).to be_nil
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
        var kind = document.querySelector("select#kind")
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
    expect(page).to have_content("Digitar")
    find("[data-lote-id]", text: "empty.jpg").click

    expect(page).to have_select("kind", selected: "Recibo", disabled: true)
    expect(page).not_to have_css("#chave", visible: true)
    expect(page.find("#chave", visible: :hidden).disabled?).to be(true)
  end

  it "selected jpg proof is blob img" do
    open_lote
    attach_file "file", write_upload("empty.jpg", "jpeg-bytes"), make_visible: true
    find("[data-lote-id]", text: "empty.jpg").click

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
    find("[data-lote-id]", text: "danfe.pdf").click

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

  it "a zero Valor keeps a Digitar row out of Pronto" do
    open_lote
    attach_file "file", write_upload("empty.jpg", "jpeg-bytes"), make_visible: true
    expect(page).to have_css("[data-lote-status]", text: "Digitar")
    find("[data-lote-id]", text: "empty.jpg").click
    find_field("amount").set("10,00")
    find_field("date").set("2026-05-10")
    find_field("payee").set("Mercado Bom Preço")
    expect(page).to have_css("[data-lote-status]", text: "Pronto")

    find_field("amount").set("0,00")

    expect(page).to have_css("[data-lote-status]", text: "Digitar")
    expect(page).to have_button("Incluir prontos (0)")
  end
end
