require "rails_helper"
require "capybara/cuprite"

RSpec.describe "Matches workspace", type: :system do
  before do
    driven_by :cuprite, screen_size: [ 1440, 900 ], options: {
      browser_options: { "no-sandbox": nil }, process_timeout: 30, timeout: 20
    }
    @account, @organization = plant_coordinator
    @month, @statement = plant_month(@organization)
    @payment = plant_payment(@statement, 22000, history: "Padaria Central", occurred_on: Date.new(2026, 5, 11))
    @document = plant_recibo(@organization, @account, payee: "Padaria Central", amount: "220,00")
    stub_google_oauth(email: @account.email, uid: @account.google_uid)
    visit "/auth/google_oauth2/callback"
  end

  def open_workspace(query = "")
    visit "/months/2026-05/matches#{query}"
  end

  def mark_fee(payment = @payment)
    payment.mark_document_exception("bank_fee")
    expect(payment.errors).to be_empty
  end

  it "workspace criterion 01" do
    open_workspace
    expect(page).to have_css("h1", text: "Casar pagamentos")
    expect(page).to have_text("maio de 2026")
  end

  it "workspace criterion 02" do
    @payment.update!(occurred_on: Date.new(2026, 5, 12))
    first = plant_payment(@statement, 7000, history: "Antigo", occurred_on: Date.new(2026, 5, 1))
    plant_payment(@statement, 8000, history: "Mesmo dia", occurred_on: Date.new(2026, 5, 1))
    open_workspace
    expect(find("[data-current='true']")['data-payment-id']).to eq(first.id.to_s)
    expect(page).to have_text("Antigo")
  end

  it "workspace criterion 03" do
    second = BankAccount.create_for(organization: @organization, name: "Conta Outra", compe: "033")
    statement = BankStatement.create!(month: @month, bank_account: second)
    plant_payment(statement, 10000, history: "Outro banco", occurred_on: Date.new(2026, 5, 20))
    open_workspace("?bank_account_id=#{second.id}")
    expect(page).to have_text("Outro banco")
    click_button "Escolher exceção"
    click_button "Tarifa bancária"
    click_button "Marcar exceção"
    expect(page).to have_current_path("/months/2026-05/matches?bank_account_id=#{second.id}")
  end

  it "workspace criterion 04" do
    open_workspace
    expect(page).to have_css("[data-row='payment']", text: "Padaria Central")
    expect(page).to have_css("[data-row='pool-document']", text: "Padaria Central")
    expect(Match.count).to eq(0)
  end

  it "workspace criterion 05" do
    @document.destroy!
    open_workspace
    expect(page).to have_text("Padaria Central")
    expect(page).to have_text("Nenhum documento selecionado")
    expect(page).to have_button("Adicionar documentos")
  end

  it "workspace criterion 06" do
    open_workspace
    uncheck "supporting_document_ids[]"
    expect(page).to have_text("Documentos R$ 0,00")
    click_button "Adicionar documentos"
    check "supporting_document_ids[]"
    expect(page).to have_text("Documentos R$ 220,00")
    expect(Match.count).to eq(0)
  end

  it "workspace criterion 07" do
    plant_payment(@statement, 1000, history: "Outro pagamento", occurred_on: Date.new(2026, 5, 12))
    open_workspace
    click_button "Adicionar outro pagamento"
    find("[data-row='payment']", text: "Outro pagamento").find("input").check
    expect(page).to have_text("Pagamentos R$ 230,00")
  end

  it "workspace criterion 08" do
    plant_payment(@statement, 1000, history: "Outro pagamento", occurred_on: Date.new(2026, 5, 12))
    plant_recibo(@organization, @account, payee: "Outro", amount: "10,00")
    open_workspace
    click_button "Adicionar outro pagamento"
    find("[data-row='payment']", text: "Outro pagamento").find("input").check
    click_button "Adicionar documentos"
    find("[data-row='pool-document']", text: "Outro").find("input").check
    click_button "Confirmar casamento"
    expect(page).to have_text(Match::BAD_SHAPE)
    expect(Match.count).to eq(0)
  end

  it "workspace criterion 09" do
    open_workspace
    expect(page).to have_text("Soma igual")
    expect(Match.count).to eq(0)
    expect(page).to have_button("Confirmar casamento")
  end

  it "workspace criterion 10" do
    open_workspace
    expect(page).to have_no_field("Observação do casamento", visible: true)
    find("summary", text: "Observação do casamento").click
    expect(page).to have_field("Observação do casamento", visible: true)
  end

  it "workspace criterion 11" do
    @payment.update!(amount_cents: 23000)
    open_workspace
    click_button "Confirmar casamento"
    expect(page).to have_text("Informe a observação do casamento")
    expect(Match.count).to eq(0)
  end

  it "workspace criterion 12" do
    plant_payment(@statement, 1000, history: "Próximo pagamento", occurred_on: Date.new(2026, 5, 12))
    open_workspace
    click_button "Confirmar casamento"
    expect(page).to have_text("Casamentos confirmados")
    expect(page).to have_css("[data-match-id]", text: "Padaria Central")
    expect(page).to have_css("[data-current='true']", text: "Próximo pagamento")
  end

  it "workspace criterion 13" do
    mark_fee
    open_workspace
    expect(page).to have_text("Nenhum pagamento com documento faltante")
    expect(page).to have_text("Casamentos confirmados")
    expect(page).to have_text("Exceções marcadas")
  end

  it "workspace criterion 14" do
    ExtraExceptionKind.create_for(organization: @organization, name: "Despesa especial", justification: "Justificativa de teste")
    open_workspace
    click_button "Escolher exceção"
    expect(page).to have_button("Tarifa bancária")
    expect(page).to have_button("Honorário do contador")
    expect(page).to have_button("Despesa especial")
  end

  it "workspace criterion 15" do
    plant_payment(@statement, 1000, history: "Outro pagamento", occurred_on: Date.new(2026, 5, 12))
    open_workspace
    click_button "Adicionar outro pagamento"
    find("[data-row='payment']", text: "Outro pagamento").find("input").check
    click_button "Escolher exceção"
    click_button "Tarifa bancária"
    expect(page).to have_button("Marcar exceção")
    expect(page).to have_text("Documentos removidos")
    expect(page).to have_text("Pagamentos R$ 220,00")
    expect(find("[data-document-id='#{@document.id}'] input", visible: false)).not_to be_checked
    expect(page).to have_no_button("Adicionar outro pagamento")
    find('[data-current="true"] input[type="checkbox"]').click
    expect(find('[data-current="true"] input[type="checkbox"]')).to be_checked
    expect(@payment.reload.document_exception_kind).to be_nil
  end

  it "workspace criterion 16" do
    open_workspace
    click_button "Escolher exceção"
    click_button "Tarifa bancária"
    click_button "Cancelar exceção"
    expect(page).to have_button("Confirmar casamento")
    expect(page).to have_text("Nenhum documento selecionado")
    expect(find("[data-document-id='#{@document.id}'] input", visible: false)).not_to be_checked
    click_button "Adicionar documentos"
    check "supporting_document_ids[]"
    expect(page).to have_text("Documentos R$ 220,00")
  end

  it "workspace criterion 17" do
    plant_payment(@statement, 1000, history: "Próximo pagamento", occurred_on: Date.new(2026, 5, 12))
    open_workspace
    click_button "Escolher exceção"
    click_button "Tarifa bancária"
    click_button "Marcar exceção"
    expect(page).to have_css("[data-exception-payment-id='#{@payment.id}']", text: "Tarifa bancária")
    expect(page).to have_css("[data-current='true']", text: "Próximo pagamento")
  end

  it "workspace criterion 18" do
    @organization.update!(bank_fee_exception_active: false)
    open_workspace
    click_button "Escolher exceção"
    expect(page).to have_no_button("Tarifa bancária")
    expect(@payment.reload.document_exception_kind).to be_nil
  end

  it "workspace criterion 19" do
    @document.update!(payee: "Fornecedor distinto", amount_cents: 20000)
    Match.confirm(month: @month, payments: [ @payment ], supporting_documents: [ @document ], observation: "Ajuste")
    open_workspace
    expect(page).to have_css("[data-match-id]", count: 1)
    within("[data-match-id]") do
      cells = all("td", minimum: 6).map(&:text)
      expect(cells[0..4]).to eq([ "11/05", "Padaria Central", "R$ 220,00", "Fornecedor distinto · 1 documento", "R$ 200,00" ])
    end
  end

  it "workspace criterion 20" do
    @document.update!(payee: "Fornecedor A", amount_cents: 12000)
    other = plant_recibo(@organization, @account, payee: "Fornecedor B", amount: "100,00", date: "2026-05-12")
    Match.confirm(month: @month, payments: [ @payment ], supporting_documents: [ @document, other ], observation: "Conferido")
    open_workspace
    find("summary", text: "Ver detalhes").click
    expect(page).to have_text("Pagamento · 11/05 · Padaria Central · Conta Principal · R$ 220,00")
    expect(page).to have_text("Recibo · 11/05 · Fornecedor A · R$ 120,00")
    expect(page).to have_text("Recibo · 12/05 · Fornecedor B · R$ 100,00")
    expect(page).to have_text("Observação: Conferido")
  end

  it "workspace criterion 21" do
    Match.confirm(month: @month, payments: [ @payment ], supporting_documents: [ @document ])
    open_workspace
    find("summary", text: "Ver detalhes").click
    click_button "Desfazer casamento"
    expect(page).to have_no_css("[data-match-id]")
    expect(page).to have_css("[data-current='true']", text: "Padaria Central")
    expect(@document.reload.match_id).to be_nil
  end

  it "workspace criterion 22" do
    mark_fee
    open_workspace
    within("[data-exception-payment-id='#{@payment.id}']") do
      expect(page).to have_text("11/05")
      expect(page).to have_text("Padaria Central")
      expect(page).to have_text("Conta Principal")
      expect(page).to have_text("R$ 220,00")
      expect(page).to have_text("Tarifa bancária")
      expect(page).to have_button("Desmarcar exceção")
    end
  end

  it "workspace criterion 23" do
    mark_fee
    open_workspace
    click_button "Desmarcar exceção"
    expect(page).to have_no_css("[data-exception-payment-id='#{@payment.id}']")
    expect(page).to have_css("[data-current='true']", text: "Padaria Central")
  end

  it "workspace criterion 24" do
    second = BankAccount.create_for(organization: @organization, name: "Conta Outra", compe: "033")
    statement = BankStatement.create!(month: @month, bank_account: second)
    other = plant_payment(statement, 1000, history: "Outro banco")
    fee_other = plant_payment(statement, 500, history: "Tarifa Outra")
    fee_principal = plant_payment(@statement, 600, history: "Tarifa Principal")
    mark_fee(fee_other)
    mark_fee(fee_principal)
    @document.update!(amount_cents: 23000)
    Match.confirm(month: @month, payments: [ @payment, other ], supporting_documents: [ @document ])
    open_workspace("?bank_account_id=#{second.id}")
    find("summary", text: "Ver detalhes").click
    expect(page).to have_text("Padaria Central")
    expect(page).to have_text("Outro banco")
    expect(page).to have_css("[data-match-id]", count: 1)
    expect(page).to have_css("[data-exception-payment-id='#{fee_other.id}']", text: "Tarifa Outra")
    expect(page).to have_no_css("[data-exception-payment-id='#{fee_principal.id}']")
  end

  it "workspace criterion 25" do
    matched_payment = plant_payment(@statement, 22000, history: "Pagamento casado")
    Match.confirm(month: @month, payments: [ matched_payment ], supporting_documents: [ @document ])
    mark_fee(@payment)
    @month.update!(closed: true)
    open_workspace
    expect(page).to have_text("Exceções marcadas")
    expect(page).to have_css("[data-match-id]", text: "Pagamento casado")
    find("summary", text: "Ver detalhes").click
    expect(page).to have_no_button("Desfazer casamento")
    expect(page).to have_no_button("Marcar exceção")
    expect(page).to have_no_button("Desmarcar exceção")
    expect(page).to have_no_button("Confirmar casamento")
  end

  it "workspace criterion 26" do
    @payment.update!(amount_cents: 23000)
    open_workspace("?bank_account_id=#{@statement.bank_account_id}")
    click_button "Confirmar casamento"
    expect(page).to have_text(Match::LESSER)
    expect(page).to have_css("input[name='bank_account_id'][value='#{@statement.bank_account_id}']", visible: false)
    expect(Match.count).to eq(0)
  end

  it "workspace criterion 27" do
    matched_payment = plant_payment(@statement, 22000, history: "Pagamento casado")
    Match.confirm(month: @month, payments: [ matched_payment ], supporting_documents: [ @document ])
    fee = plant_payment(@statement, 500, history: "Tarifa bancária")
    mark_fee(fee)
    open_workspace
    [ 375, 1440 ].each do |width|
      page.current_window.resize_to(width, 900)
      expect(page).to have_button("Confirmar casamento")
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to eq(true)
      expect(page).to have_css(".match-table-scroll", count: 2)
      scroll = page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll('.match-table-scroll')).map((el) => {
          el.scrollLeft = el.scrollWidth;
          return { width: el.clientWidth, content: el.scrollWidth, left: el.scrollLeft };
        })
      JS
      if width == 375
        expect(scroll).to all(satisfy { |item| item["content"] > item["width"] && item["left"] > 0 })
      else
        expect(scroll).to all(satisfy { |item| item["content"] <= item["width"] || item["left"] > 0 })
      end
    end
  end

  it "workspace criterion 28" do
    open_workspace
    page.execute_script("document.querySelector('[data-month-match-target=exceptionButton]').focus()")
    page.send_keys(:enter)
    expect(page).to have_button("Tarifa bancária")
    page.send_keys(:escape)
    expect(page).to have_no_button("Tarifa bancária")
    page.execute_script("document.querySelector('[data-month-match-target=exceptionButton]').focus()")
    page.send_keys(:enter)
    page.execute_script("document.querySelector('[data-kind=bank_fee]').focus()")
    page.send_keys(:enter)
    expect(page).to have_button("Marcar exceção")
  end
end
