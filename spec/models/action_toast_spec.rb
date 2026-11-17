require "rails_helper"

RSpec.describe ActionToast do
  def organization(**attrs)
    create_organization!(name: "ONG Norte", **attrs)
  end

  def month
    Month.new(year_month: "2026-05")
  end

  describe "naming the object that changed" do
    it "names the focused organization" do
      expect(ActionToast.focus(organization)).to eq("Agora em ONG Norte.")
    end

    it "names the invited email" do
      invite = Invite.new(organization: organization, email: "guest@example.com")

      expect(ActionToast.invite_sent(invite)).to eq("Convite enviado para guest@example.com.")
      expect(ActionToast.invite_resent(invite)).to eq("Convite reenviado para guest@example.com.")
      expect(ActionToast.invite_cancelled("guest@example.com")).to eq("Convite para guest@example.com cancelado.")
    end

    it "names the revoked access email" do
      expect(ActionToast.access_revoked("ana@ong.org")).to eq("Acesso de ana@ong.org revogado.")
    end

    it "names the month on open, close, reopen and restore" do
      expect(ActionToast.month_opened(month)).to eq("Fechamento de maio de 2026 aberto.")
      expect(ActionToast.month_closed(month)).to eq("Maio de 2026 fechado. Pacote gravado na pasta do mês.")
      expect(ActionToast.month_reopened(month)).to eq("Maio de 2026 reaberto.")
      expect(ActionToast.month_folder_restored(month)).to eq("Pasta de maio de 2026 restaurada no arquivo do pacote.")
    end

    it "names the saved accountant and the package folder" do
      expect(ActionToast.accountant_saved(organization(accountant_presentation_name: "Ana Contábil")))
        .to eq("Contador salvo: Ana Contábil.")
      expect(ActionToast.package_archive_saved).to eq("Pasta do pacote salva.")
    end

    it "names the certificate titular and validity" do
      with_certificate = organization(
        sefaz_titular_cnpj: "11222333000181",
        sefaz_not_after: Date.new(2027, 9, 18)
      )

      expect(ActionToast.certificate_installed(with_certificate))
        .to eq("Certificado A1 de 11.222.333/0001-81 instalado, válido até 18/09/2027.")
      expect(ActionToast.certificate_removed("11.222.333/0001-81"))
        .to eq("Certificado A1 de 11.222.333/0001-81 removido.")
    end

    it "names the bank account and the state it entered" do
      _, organization = plant_coordinator
      bank_account = BankAccount.create_for(organization: organization, name: "Conta Principal", compe: "001")

      expect(ActionToast.bank_account_created(bank_account)).to eq("Conta bancária criada: Conta Principal.")
      expect(ActionToast.bank_account_saved(bank_account)).to eq("Conta bancária salva: Conta Principal.")
      expect(ActionToast.bank_account_deactivated(bank_account)).to eq("Conta bancária desativada: Conta Principal.")
      expect(ActionToast.bank_account_reactivated(bank_account)).to eq("Conta bancária reativada: Conta Principal.")
    end

    it "names the extra exception kind and the state it entered" do
      _, organization = plant_coordinator
      kind = ExtraExceptionKind.create_for(
        organization: organization, name: "Doação", justification: "Isento de documento de suporte."
      )

      expect(ActionToast.extra_exception_kind_created(kind)).to eq("Tipo extra criado: Doação.")
      expect(ActionToast.extra_exception_kind_saved(kind)).to eq("Tipo extra salvo: Doação.")
      expect(ActionToast.extra_exception_kind_activated(kind)).to eq("Tipo extra ativado: Doação.")
      expect(ActionToast.extra_exception_kind_deactivated(kind)).to eq("Tipo extra desativado: Doação.")
      expect(ActionToast.extra_exception_kind_deleted("Doação")).to eq("Tipo extra excluído: Doação.")
    end

    it "names the base document exception by its setup name" do
      expect(ActionToast.base_document_exception_changed("bank_fee", false))
        .to eq("Exceção Tarifa bancária desativada.")
      expect(ActionToast.base_document_exception_changed("accountant_fee", true))
        .to eq("Exceção Honorário do contador reativada.")
    end

    it "names the imported statement account and its movement counts" do
      _, organization = plant_coordinator
      _opened, statement = plant_month(organization)
      plant_inflow(statement, 6300)
      plant_payment(statement, 22000)

      expect(ActionToast.statement_imported(statement))
        .to eq("Extrato de Conta Principal importado: 1 recebimento e 1 pagamento.")
    end

    it "names the confirmed match amount and payee" do
      expect(ActionToast.match_confirmed(payments: [ Payment.new(amount_cents: 22000) ], payee: "Padaria Central"))
        .to eq("Casamento confirmado: R$ 220,00 com Padaria Central.")
    end

    it "names the confirmed match payment count and payee" do
      payments = [ Payment.new(amount_cents: 10000), Payment.new(amount_cents: 12000) ]

      expect(ActionToast.match_confirmed(payments: payments, payee: "Padaria Central"))
        .to eq("Casamento confirmado: 2 pagamentos com Padaria Central.")
    end

    it "names the dissolved match payee" do
      expect(ActionToast.match_dissolved("Padaria Central")).to eq("Casamento desfeito: Padaria Central.")
    end

    it "names the marked exception kind and the payment amount" do
      bank_fee = Payment.new(amount_cents: 4500, document_exception_kind: "bank_fee")
      accountant_fee = Payment.new(amount_cents: 4500, document_exception_kind: "accountant_fee")
      extra = Payment.new(amount_cents: 4500, extra_exception_kind: ExtraExceptionKind.new(name: "Doação"))

      expect(ActionToast.document_exception_marked(bank_fee)).to eq("Exceção marcada: Tarifa bancária, R$ 45,00.")
      expect(ActionToast.document_exception_marked(accountant_fee)).to eq("Exceção marcada: Honorário do contador, R$ 45,00.")
      expect(ActionToast.document_exception_marked(extra)).to eq("Exceção marcada: Doação, R$ 45,00.")
    end

    it "names the unmarked exception amount" do
      expect(ActionToast.document_exception_unmarked(Payment.new(amount_cents: 4500)))
        .to eq("Exceção removida de R$ 45,00.")
    end

    it "names the returned document payee" do
      expect(ActionToast.document_returned("Padaria Central"))
        .to eq("Documento de Padaria Central devolvido para Sem mês.")
    end

    it "names the inserted document kind, payee and amount" do
      recibo = SupportingDocument.new(kind: "recibo", payee: "Padaria Silva", amount_cents: 12000)
      nota = SupportingDocument.new(kind: "nota_fiscal", payee: "Padaria Silva", amount_cents: 12000)

      expect(ActionToast.document_inserted(recibo))
        .to eq("Recibo de Padaria Silva, R$ 120,00, incluído.")
      expect(ActionToast.document_inserted(nota))
        .to eq("Nota fiscal de Padaria Silva, R$ 120,00, incluída.")
    end

    it "names the updated, deleted and SEFAZ-confirmed document payee" do
      expect(ActionToast.document_updated("Padaria Silva")).to eq("Documento de Padaria Silva atualizado.")
      expect(ActionToast.document_deleted("Padaria Silva")).to eq("Documento de Padaria Silva excluído.")
      expect(ActionToast.document_sefaz_confirmed("Padaria Silva"))
        .to eq("Nota fiscal de Padaria Silva confirmada na SEFAZ.")
    end

    it "names the declared and changed justification amount" do
      expect(ActionToast.justification_declared(Justification.new(amount_cents: 30000)))
        .to eq("Justificativa de R$ 300,00 registrada.")
      expect(ActionToast.justification_changed(Justification.new(amount_cents: 35000)))
        .to eq("Justificativa alterada para R$ 350,00.")
    end
  end

  describe "truncation" do
    it "truncates a named value to forty characters" do
      payee = "a" * 44

      message = ActionToast.document_updated(payee)

      expect(message).to eq("Documento de #{"a" * 39}… atualizado.")
      expect(message).to include("a" * 39 + "…")
    end

    it "keeps a named value of exactly forty characters" do
      payee = "b" * 40

      expect(ActionToast.document_updated(payee)).to eq("Documento de #{payee} atualizado.")
    end

    it "truncates a payee of the two-hundred-character maximum" do
      message = ActionToast.document_deleted("c" * 200)

      expect(message).to eq("Documento de #{"c" * 39}… excluído.")
    end
  end

  describe "the copy rules" do
    it "renders money through format_reais" do
      expect(ActionToast.justification_declared(Justification.new(amount_cents: 12000)))
        .to include("R$ 120,00")
    end

    it "never returns Pronto" do
      messages = [
        ActionToast.focus(organization),
        ActionToast.package_archive_saved,
        ActionToast.document_updated("Padaria Silva"),
        ActionToast.document_exception_unmarked(Payment.new(amount_cents: 4500))
      ]

      expect(messages).to all(satisfy { |message| !message.include?("Pronto") })
    end

    it "returns plain text, leaving escaping to the view" do
      expect(ActionToast.document_updated("Padaria & Silva <b>"))
        .to eq("Documento de Padaria & Silva <b> atualizado.")
    end
  end
end
