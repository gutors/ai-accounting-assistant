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
    "4326051122233300018155001000000001112345#{index.to_s.rjust(2, "0")}"
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
    one = find("[data-lote-one]")
    expect(one[:class]).to include("ds-btn-secondary")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-lote-one]')).paddingTop")).to eq("8px")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-lote-one]')).paddingLeft")).to eq("16px")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-lote-one]')).backgroundColor")).to eq("rgba(0, 0, 0, 0)")
    retirar = find("[data-lote-remove]")
    expect(retirar[:class]).to include("ds-btn-secondary")
    expect(page.evaluate_script("getComputedStyle(document.querySelector('[data-lote-remove]')).color")).to include("180, 55, 42")
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
end
