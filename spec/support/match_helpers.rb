module MatchHelpers
  def plant_month(organization, year_month: "2026-05")
    month = Month.open(organization: organization, year_month: year_month)
    bank_account = organization.bank_accounts.order(:id).first
    bank_account ||= BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")
    statement = month.bank_statements.find_by(bank_account: bank_account)
    statement ||= BankStatement.create!(month: month, bank_account: bank_account)
    [ month, statement ]
  end

  def plant_payment(statement, amount_cents, history: "Pix", occurred_on: Date.new(2026, 5, 20))
    statement.payments.create!(occurred_on: occurred_on, amount_cents: amount_cents, history: history)
  end

  def plant_inflow(statement, amount_cents, history: "Pix - Recebido")
    statement.inflows.create!(occurred_on: Date.new(2026, 5, 4), amount_cents: amount_cents, history: history)
  end

  def plant_recibo(organization, account, payee:, amount:, date: "2026-05-11")
    SupportingDocument.insert(
      organization: organization,
      account: account,
      kind: "recibo",
      amount: amount,
      date: date,
      payee: payee,
      photo: photo_named("recibo-#{payee.parameterize}.jpg")
    )
  end

  def pool_html(body)
    body[body.index("Documentos sem casamento")..]
  end

  def pool_close_document_ids(body)
    Nokogiri::HTML(pool_html(body)).css('input[name="supporting_document_ids[]"]').map { |input| input["value"].to_i }
  end

  def page_close_document_ids(body)
    Nokogiri::HTML(body).css('input[name="supporting_document_ids[]"]').map { |input| input["value"].to_i }
  end

  def recebimentos_html(body)
    body[body.index("Recebimentos")...body.index("Pagamentos")]
  end

  def pagamentos_html(body)
    body[body.index("Pagamentos")...body.index("Documentos sem casamento")]
  end

  def payment_row_html(body, history:)
    pagamentos_html(body).scan(%r{<li class="mb-2">.*?</li>}m).find { |li| li.include?(history) }
  end

  def payment_status_html(body, history:)
    payment_row_html(body, history: history).split("<form").first
  end

  def selected_named_values(html, name)
    Nokogiri::HTML(html).css(%(input[name="#{name}"])).filter_map do |input|
      next unless input["type"] == "hidden" || input.has_attribute?("checked")

      input["value"]
    end
  end

  def n1_match_form_html(body)
    form = Nokogiri::HTML(body).css("form").find do |node|
      node.at_css(%(input[type="submit"][value="Confirmar casamento N:1"]))
    end
    form&.to_html.to_s
  end
end
