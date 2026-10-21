require "capybara/cuprite"

module LoteSystemHelpers
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

  def wait_one_xml
    expect(page).to have_css("section[data-controller=document-lote] h2", exact_text: "Incluir documento")
    expect(page).to have_field("amount", with: "155,00", disabled: true)
  end

  def expect_no_situacao_sheet
    expect(page).to have_no_css("[data-document-lote-target=sheet] .lote-head")
    expect(page).to have_no_css("[data-lote-ready]")
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
end

RSpec.shared_context "lote system" do
  include LoteSystemHelpers

  before do
    driven_by :cuprite, screen_size: [ 1280, 900 ], options: {
      browser_options: { "no-sandbox": nil },
      process_timeout: 30,
      timeout: 20
    }
  end
end
