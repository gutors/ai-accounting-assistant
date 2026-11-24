require "rails_helper"
require "capybara/cuprite"

RSpec.describe "Month matches layout", type: :system do
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

  def plant_open_matches
    account, organization = plant_coordinator
    month, statement = plant_month(organization)
    statement.bank_account.update!(name: "Conta Principal")
    plant_payment(statement, 22000, history: "Pix enviado — Padaria Central", occurred_on: Date.new(2026, 5, 11))
    plant_recibo(organization, account, payee: "Padaria Central", amount: "220,00")
    plant_recibo(organization, account, payee: "Mercado Menos", amount: "200,00", date: "2026-05-10")
    plant_recibo(organization, account, payee: "Mercado Mais", amount: "250,00", date: "2026-05-09")
    [ account, organization, month ]
  end

  it "workspace has two columns at 1100px and stacks on narrow screens" do
    account, _organization, _month = plant_open_matches
    sign_in_through_google(account)

    visit "/months/2026-05/matches"
    expect(page).to have_css(".match-workspace")

    page.current_window.resize_to(1100, 900)
    columns = page.evaluate_script(<<~JS)
      (function() {
        const split = document.querySelector(".match-workspace");
        const style = getComputedStyle(split);
        const tracks = style.gridTemplateColumns.split(" ").map((value) => parseFloat(value));
        const headings = Array.from(split.querySelectorAll("h2")).map((node) => node.textContent.trim());
        return { display: style.display, tracks, headings, trackCount: tracks.length };
      })()
    JS
    expect(columns["display"]).to eq("grid")
    expect(columns["headings"]).to eq([ "Pagamentos em análise", "Documentos selecionados" ])
    expect(columns["trackCount"]).to eq(2)
    expect(columns["tracks"][0]).to be_within(1).of(columns["tracks"][1])

    page.current_window.resize_to(375, 900)
    stacked = page.evaluate_script(<<~JS)
      (function() {
        const split = document.querySelector(".match-workspace");
        const style = getComputedStyle(split);
        const tracks = style.gridTemplateColumns.trim() === "none"
          ? []
          : style.gridTemplateColumns.split(" ").map((value) => parseFloat(value)).filter((value) => !Number.isNaN(value));
        const headings = Array.from(split.querySelectorAll("h2")).map((node) => node.textContent.trim());
        return { trackCount: tracks.length, headings };
      })()
    JS
    expect(stacked["trackCount"]).to eq(1)
    expect(stacked["headings"]).to eq([ "Pagamentos em análise", "Documentos selecionados" ])

    source = Rails.root.join("app/assets/tailwind/application.css").read
    expect(source).to include("@media (min-width: 1100px)")
    expect(source).to include("@media (min-width: 768px)")

    page.current_window.resize_to(768, 900)
    density = page.evaluate_script(<<~JS)
      (function() {
        const row = document.querySelector('[data-row="payment"]');
        const pool = document.querySelector('[data-row="pool-document"] input:checked').closest('[data-row="pool-document"]');
        const child = row.firstElementChild;
        const rowStyle = getComputedStyle(row);
        const childStyle = getComputedStyle(child);
        return {
          rowDisplay: rowStyle.display,
          poolDisplay: pool ? getComputedStyle(pool).display : null,
          paddingTop: childStyle.paddingTop,
          paddingBottom: childStyle.paddingBottom,
          borderLeft: rowStyle.borderLeftWidth,
          className: row.className
        };
      })()
    JS
    expect(density["rowDisplay"]).to eq("flex")
    expect(density["poolDisplay"]).to eq("flex")
    expect(density["className"]).to include("match-picker-row")
  end

  it "totalling line sums and verdicts including empty side" do
    account, _organization, _month = plant_open_matches
    sign_in_through_google(account)
    visit "/months/2026-05/matches"

    click_button "Adicionar documento"
    payment = find('[data-row="payment"] input[type="checkbox"]')
    padaria = find('[data-row="pool-document"]', text: "Padaria Central").find('input[type="checkbox"]')
    menos = find('[data-row="pool-document"]', text: "Mercado Menos").find('input[type="checkbox"]')
    mais = find('[data-row="pool-document"]', text: "Mercado Mais").find('input[type="checkbox"]')
    within("#match-confirm") do
      expect(page).to have_text(/Total dos pagamentos\s+R\$ 220,00/)
      expect(page).to have_text(/Total dos documentos\s+R\$ 220,00/)
      expect(page).to have_text("Valores conferem")
    end

    padaria.click
    menos.click
    within("#match-confirm") do
      expect(page).to have_text(/Total dos documentos\s+R\$ 200,00/)
      expect(page).to have_text("Documentos somam menos")
      expect(page).to have_no_text("Valores conferem")
    end

    menos.click
    mais.click
    within("#match-confirm") do
      expect(page).to have_text(/Total dos documentos\s+R\$ 250,00/)
      expect(page).to have_text("Documentos somam mais")
    end

    mais.click
    within("#match-confirm") do
      expect(page).to have_text(/Total dos documentos\s+R\$ 0,00/)
      expect(page).to have_text(/Total dos pagamentos\s+R\$ 220,00/)
      expect(page).to have_no_text("Valores conferem")
      expect(page).to have_no_text("Documentos somam menos")
      expect(page).to have_no_text("Documentos somam mais")
    end

    payment.click
    padaria.click
    within("#match-confirm") do
      expect(page).to have_text(/Total dos pagamentos\s+R\$ 0,00/)
      expect(page).to have_text(/Total dos documentos\s+R\$ 220,00/)
      expect(page).to have_no_text("Valores conferem")
    end
  end

  it "workspace groups confirmation and compact observation with the payment" do
    account, _organization, _month = plant_open_matches
    sign_in_through_google(account)
    visit "/months/2026-05/matches"

    expect(page).to have_css("h2", text: "Pagamentos em análise")
    expect(page).to have_css("#match-confirm")
    styles = page.evaluate_script(<<~JS)
      (function() {
        const band = document.querySelector(".match-workspace");
        const confirm = document.querySelector("#match-confirm");
        const bandStyle = getComputedStyle(band);
        const confirmStyle = getComputedStyle(confirm);
        return {
          containsHeading: band.querySelector("h2") && band.querySelector("h2").textContent.trim() === "Pagamentos em análise",
          insideConfirm: confirm.contains(band),
          observationClosed: confirm.querySelector("details") && !confirm.querySelector("details").open,
          confirmBorderTopWidth: confirmStyle.borderTopWidth
        };
      })()
    JS
    expect(styles["containsHeading"]).to eq(true)
    expect(styles["insideConfirm"]).to eq(true)
    expect(styles["observationClosed"]).to eq(true)
    expect(styles["confirmBorderTopWidth"]).to eq("0px")
  end

  it "equal suggestion is selected but requires explicit confirmation" do
    account, _organization, _month = plant_open_matches
    sign_in_through_google(account)
    visit "/months/2026-05/matches"

    expect(page).to have_text("Valores conferem")
    expect(Match.count).to eq(0)
    click_button "Confirmar casamento"
    expect(page).to have_current_path("/months/2026-05/matches")
    expect(Match.count).to eq(1)
    expect(page).to have_css("[data-match-id]", text: "Pix enviado — Padaria Central")
    expect(page).to have_no_css('[data-row="pool-document"]', text: "Padaria Central")
  end

  it "lesser suggestion checks rows and does not persist" do
    account, organization = plant_coordinator
    month, statement = plant_month(organization)
    plant_payment(statement, 150000, history: "TED — Aluguel sede", occurred_on: Date.new(2026, 5, 11))
    plant_recibo(organization, account, payee: "Imobiliária Serra", amount: "1400,00", date: "2026-05-11")
    sign_in_through_google(account)
    visit "/months/2026-05/matches"

    expect(Match.count).to eq(0)
    pay = find('[data-row="payment"]', text: "TED — Aluguel sede")
    expect(pay.find('input[type="checkbox"]')).to be_checked
    doc = find('[data-row="pool-document"]', text: "Imobiliária Serra")
    expect(doc.find('input[type="checkbox"]')).to be_checked
    within("#match-confirm") do
      expect(page).to have_text("Documentos somam menos")
      expect(find("#observation_match", visible: false).value).to eq("")
    end
  end
  it "selects and clears the matching account" do
    account, organization, month = plant_open_matches
    original_statement = month.bank_statements.first
    other = BankAccount.create_for(organization: organization, name: "Conta Outra", compe: "033")
    statement = BankStatement.create!(month: month, bank_account: other)
    plant_payment(statement, 5000, history: "Pagamento da outra conta")
    [ [ original_statement, "Principal" ], [ statement, "Outra" ] ].each do |bank_statement, name|
      payment = plant_payment(bank_statement, 7000, history: "Casado #{name}")
      document = plant_recibo(organization, account, payee: "Documento #{name}", amount: "70,00")
      expect(Match.confirm(month: month, payments: [ payment ], supporting_documents: [ document ]).errors).to be_empty
      fee = plant_payment(bank_statement, 300, history: "Tarifa #{name}")
      fee.mark_document_exception("bank_fee")
      expect(fee.errors).to be_empty
    end
    sign_in_through_google(account)
    visit "/months/2026-05/matches"
    select "Conta Outra", from: "Filtrar por conta bancária"
    expect(page).to have_text("Pagamento da outra conta")
    expect(page).to have_text("1 pagamento com documento faltante")
    expect(page).to have_css("[data-match-id]", text: "Casado Outra")
    expect(page).to have_no_css("[data-match-id]", text: "Casado Principal")
    expect(page).to have_css("[data-exception-payment-id]", text: "Tarifa Outra")
    expect(page).to have_no_css("[data-exception-payment-id]", text: "Tarifa Principal")
    select "Todas as contas", from: "Filtrar por conta bancária"
    expect(page).to have_text("Pix enviado — Padaria Central")
    expect(page).to have_text("2 pagamentos com documento faltante")
    expect(page).to have_css("[data-match-id]", text: "Casado Principal")
    expect(page).to have_css("[data-match-id]", text: "Casado Outra")
    expect(page).to have_css("[data-exception-payment-id]", text: "Tarifa Principal")
    expect(page).to have_css("[data-exception-payment-id]", text: "Tarifa Outra")
  end

  it "shows full names below the value line" do
    account, _organization, _month = plant_open_matches
    sign_in_through_google(account)
    visit "/months/2026-05/matches"
    click_button "Adicionar documento"
    page.all(".match-picker-row", visible: true).each do |row|
      expect(row).to have_css(".match-row-top .match-meta")
      expect(row).to have_css(".match-row-top strong")
      expect(row).to have_css(".match-name", visible: true)
      expect(row.evaluate_script("getComputedStyle(this.querySelector('.match-name')).overflowWrap")).to eq("anywhere")
      checkbox = row.find("input")
      expect(checkbox.evaluate_script("this.getBoundingClientRect().width")).to eq(16)
      expect(checkbox.evaluate_script("this.getBoundingClientRect().height")).to eq(16)
    end
  end

  it "adds payments and documents in their own list" do
    account, organization, month = plant_open_matches
    plant_payment(month.bank_statements.first, 1000, history: "Outro pagamento", occurred_on: Date.new(2026, 5, 12))
    plant_payment(month.bank_statements.first, 2000, history: "Pagamento não selecionado", occurred_on: Date.new(2026, 5, 13))
    plant_recibo(organization, account, payee: "Outro documento", amount: "10,00")
    plant_recibo(organization, account, payee: "Documento não selecionado", amount: "20,00")
    sign_in_through_google(account)
    visit "/months/2026-05/matches"
    click_button "Adicionar pagamento"
    find('[data-row="payment"]', text: "Outro pagamento").find("input").check
    expect(page).to have_text(/Total dos pagamentos\s+R\$ 230,00/)
    within(".match-sheet", text: "Pagamentos em análise") { click_button "Concluir seleção" }
    expect(page).to have_text("Outro pagamento")
    expect(page).to have_no_css('[data-row="payment"]', text: "Pagamento não selecionado")
    expect(page).to have_css('[data-row="payment"][hidden]', text: "Pagamento não selecionado", visible: :hidden)
    click_button "Adicionar documento"
    find('[data-row="pool-document"]', text: "Outro documento").find("input").check
    expect(page).to have_text(/Total dos documentos\s+R\$ 230,00/)
    within(".match-sheet", text: "Documentos selecionados") { click_button "Concluir seleção" }
    expect(page).to have_text("Outro documento")
    expect(page).to have_no_css('[data-row="pool-document"]', text: "Documento não selecionado")
    expect(page).to have_css('[data-row="pool-document"][hidden]', text: "Documento não selecionado", visible: :hidden)
  end

  it "shows signed and colored differences" do
    account, _organization, _month = plant_open_matches
    sign_in_through_google(account)
    visit "/months/2026-05/matches"
    difference = find(".match-difference")
    expect(difference["data-tone"]).to eq("equal")
    expect(difference).to have_text("R$ 0,00")
    expect(difference).to have_text("Valores conferem")
    expect(difference.evaluate_script("getComputedStyle(this).color")).to eq("rgb(34, 84, 60)")
    expect(difference.evaluate_script("getComputedStyle(this).backgroundColor")).to eq("rgb(229, 240, 231)")
    click_button "Adicionar documento"
    find('[data-row="pool-document"]', text: "Padaria Central").find("input").uncheck
    expect(difference["data-tone"]).to eq("pending")
    expect(difference).to have_text("Aguardando seleção")
    expect(difference.evaluate_script("getComputedStyle(this).color")).to eq("rgb(27, 50, 41)")
    expect(difference.evaluate_script("getComputedStyle(this).backgroundColor")).to eq("rgb(238, 241, 237)")
    find('[data-row="pool-document"]', text: "Mercado Menos").find("input").check
    expect(difference["data-tone"]).to eq("less")
    expect(difference).to have_text("− R$ 20,00")
    expect(difference).to have_text("Documentos somam menos")
    expect(difference.evaluate_script("getComputedStyle(this).color")).to eq("rgb(180, 55, 42)")
    expect(difference.evaluate_script("getComputedStyle(this).backgroundColor")).to eq("rgb(248, 235, 232)")
    find('[data-row="pool-document"]', text: "Mercado Menos").find("input").uncheck
    find('[data-row="pool-document"]', text: "Mercado Mais").find("input").check
    expect(difference["data-tone"]).to eq("more")
    expect(difference).to have_text("+ R$ 30,00")
    expect(difference).to have_text("Documentos somam mais")
    expect(difference.evaluate_script("getComputedStyle(this).color")).to eq("rgb(35, 91, 133)")
    expect(difference.evaluate_script("getComputedStyle(this).backgroundColor")).to eq("rgb(231, 239, 246)")
    find('[data-row="payment"] input').uncheck
    expect(difference["data-tone"]).to eq("pending")
    expect(difference).to have_text("Aguardando seleção")
    expect(difference.evaluate_script("getComputedStyle(this).color")).to eq("rgb(27, 50, 41)")
    expect(difference.evaluate_script("getComputedStyle(this).backgroundColor")).to eq("rgb(238, 241, 237)")
    page.execute_script(<<~JS)
      const payment = document.querySelector('[data-row="payment"] input');
      const documentInput = document.querySelector('[data-row="pool-document"] input:checked');
      payment.closest('[data-row]').dataset.cents = "9007199254740993";
      documentInput.closest('[data-row]').dataset.cents = "9007199254740992";
      payment.checked = true;
      payment.dispatchEvent(new Event("input", { bubbles: true }));
    JS
    expect(difference["data-tone"]).to eq("less")
    expect(difference).to have_text("− R$ 0,01")
  end

  it "opens the required observation on shortfall" do
    account, organization = plant_coordinator
    _month, statement = plant_month(organization)
    plant_payment(statement, 150000, history: "Aluguel")
    plant_recibo(organization, account, payee: "Aluguel", amount: "1400,00")
    sign_in_through_google(account)
    visit "/months/2026-05/matches"
    expect(page).to have_text("Obrigatória")
    find("summary", text: "Observação do casamento").click
    fill_in "Observação do casamento", with: "  "
    find("summary", text: "Observação do casamento").click
    page.execute_script('document.querySelector("#match-confirm").dataset.beforeSubmit = "same-dom"')
    click_button "Confirmar casamento"
    expect(page).to have_css('[role="alert"]', text: "Informe a observação do casamento")
    expect(page).to have_css('#match-confirm[data-before-submit="same-dom"]')
    expect(page.evaluate_script('document.activeElement.matches("[role=alert]")')).to eq(true)
    expect(page).to have_field("Observação do casamento", visible: true)
    expect(Match.count).to eq(0)
  end

  it "chooses and cancels an outlined exception" do
    account, organization, _month = plant_open_matches
    organization.update!(bank_fee_exception_active: false)
    sign_in_through_google(account)
    visit "/months/2026-05/matches"
    dimensions = page.evaluate_script(<<~JS)
      (() => {
        const primary = document.querySelector(".match-action").getBoundingClientRect();
        const secondary = document.querySelector(".match-exception-button").getBoundingClientRect();
        return [primary.width, primary.height, secondary.width, secondary.height];
      })()
    JS
    expect(dimensions[0]).to be_within(1).of(dimensions[2])
    expect(dimensions[1]).to eq(dimensions[3])
    click_button "Escolher exceção"
    expect(page).to have_no_button("Tarifa bancária")
    click_button "Honorário do contador"
    expect(page).to have_button("Marcar exceção")
    expect(page).to have_text("Documentos removidos")
    click_button "Cancelar exceção"
    expect(page).to have_button("Confirmar casamento")
    expect(page).to have_text("Nenhum documento selecionado")
  end

  it "confirms a match and advances within the account" do
    account, _organization, month = plant_open_matches
    statement = month.bank_statements.first
    plant_payment(statement, 1000, history: "Próximo pagamento", occurred_on: Date.new(2026, 5, 12))
    sign_in_through_google(account)
    visit "/months/2026-05/matches?bank_account_id=#{statement.bank_account_id}"
    click_button "Confirmar casamento"
    expect(page).to have_current_path("/months/2026-05/matches?bank_account_id=#{statement.bank_account_id}")
    expect(page).to have_css('[data-current="true"]', text: "Próximo pagamento")
  end

  it "workspace fits desktop and phone widths" do
    account, _organization, _month = plant_open_matches
    sign_in_through_google(account)
    visit "/months/2026-05/matches"
    [ 1100, 390 ].each do |width|
      page.driver.browser.page.command("Emulation.setDeviceMetricsOverride", width: width, height: 900, deviceScaleFactor: 1, mobile: false)
      result = page.evaluate_script(<<~JS)
        (() => {
          const workspace = document.querySelector(".match-workspace");
          const sections = workspace.querySelectorAll("section");
          return {
            first: sections[0].getBoundingClientRect().top,
            second: sections[1].getBoundingClientRect().top,
            overflow: document.documentElement.scrollWidth > document.documentElement.clientWidth
          };
        })()
      JS
      expect(result["first"] == result["second"]).to eq(width == 1100)
      expect(result["overflow"]).to eq(false)
      next unless width == 390

      actions = page.evaluate_script(<<~JS)
        (() => {
          const buttons = Array.from(document.querySelectorAll(".match-action, .match-exception-button"));
          return buttons.map((button) => {
            const bounds = button.getBoundingClientRect();
            const range = document.createRange();
            range.selectNodeContents(button.querySelector("span") || button);
            const labelRects = Array.from(range.getClientRects());
            return {
              width: bounds.width,
              height: bounds.height,
              lines: labelRects.length,
              contained: labelRects.every((label) =>
                label.left >= bounds.left && label.right <= bounds.right &&
                label.top >= bounds.top && label.bottom <= bounds.bottom
              ),
              overflow: button.scrollWidth > button.clientWidth || button.scrollHeight > button.clientHeight
            };
          });
        })()
      JS
      expect(actions.size).to eq(2)
      expect(actions[0]["lines"]).to eq(2), actions.inspect
      expect(actions[0]["width"]).to be_within(1).of(actions[1]["width"])
      expect(actions[0]["height"]).to be_within(1).of(actions[1]["height"])
      expect(actions).to all(include("contained" => true, "overflow" => false))
      click_button "Escolher exceção"
      menu = page.evaluate_script(<<~JS)
        (() => {
          const rect = document.querySelector("#exception-list").getBoundingClientRect();
          return { left: rect.left, right: rect.right, viewport: window.innerWidth };
        })()
      JS
      expect(menu["left"]).to be >= 0
      expect(menu["right"]).to be <= menu["viewport"]
    end
  end
end
