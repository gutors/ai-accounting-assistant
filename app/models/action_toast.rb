# The one sentence a finished action reports back to the person.
#
# One function per action, called from the controller that performed it. The message names the
# object that changed and the value the person just chose, so a screen with several rows of the
# same kind still says which one moved. Copy lives here, not at the call sites, so the wording has
# a single review point.
class ActionToast
  NAME_MAX = 40
  SEPARATOR = " e "

  class << self
    include ApplicationHelper

    def focus(organization)
      "Agora em #{name_of(organization.name)}."
    end

    def invite_sent(invite)
      "Convite enviado para #{name_of(invite.email)}."
    end

    def invite_resent(invite)
      "Convite reenviado para #{name_of(invite.email)}."
    end

    def invite_cancelled(email)
      "Convite para #{name_of(email)} cancelado."
    end

    def access_revoked(email)
      "Acesso de #{name_of(email)} revogado."
    end

    def month_opened(month)
      "Fechamento de #{month_title(month.year_month)} aberto."
    end

    def month_closed(month)
      "#{month_title(month.year_month).capitalize} fechado. Pacote gravado na pasta do mês."
    end

    def month_reopened(month)
      "#{month_title(month.year_month).capitalize} reaberto."
    end

    def month_folder_restored(month)
      "Pasta de #{month_title(month.year_month)} restaurada no arquivo do pacote."
    end

    def statement_imported(bank_statement)
      "Extrato de #{name_of(bank_statement.bank_account.name)} importado#{movement_counts(bank_statement)}."
    end

    def match_confirmed(payments:, payee:)
      if payments.one?
        "Casamento confirmado: #{money(payments.first.amount_cents)} com #{name_of(payee)}."
      else
        "Casamento confirmado: #{payments.size} pagamentos com #{name_of(payee)}."
      end
    end

    def match_dissolved(payee)
      "Casamento desfeito: #{name_of(payee)}."
    end

    def document_exception_marked(payment)
      "Exceção marcada: #{name_of(exception_label(payment))}, #{money(payment.amount_cents)}."
    end

    def document_exception_unmarked(payment)
      "Exceção removida de #{money(payment.amount_cents)}."
    end

    def document_returned(payee)
      "Documento de #{name_of(payee)} devolvido para Sem mês."
    end

    def document_inserted(document)
      noun = document.recibo? ? "Recibo" : "Nota fiscal"
      participle = document.recibo? ? "incluído" : "incluída"
      "#{noun} de #{name_of(document.payee)}, #{money(document.amount_cents)}, #{participle}."
    end

    # A lote has no single payee or amount to name, so it counts the rows instead. One row keeps
    # the sentence of a single insert, which is what the person would have got posting it alone.
    def documents_inserted(documents)
      documents = Array(documents)
      return document_inserted(documents.first) if documents.one?

      "Documentos incluídos: #{documents.size}."
    end

    def document_updated(payee)
      "Documento de #{name_of(payee)} atualizado."
    end

    def document_deleted(payee)
      "Documento de #{name_of(payee)} excluído."
    end

    def document_sefaz_confirmed(payee)
      "Nota fiscal de #{name_of(payee)} confirmada na SEFAZ."
    end

    def justification_declared(justification)
      "Justificativa de #{money(justification.amount_cents)} registrada."
    end

    def justification_changed(justification)
      "Justificativa alterada para #{money(justification.amount_cents)}."
    end

    def accountant_saved(organization)
      "Contador salvo: #{name_of(organization.accountant_presentation_name)}."
    end

    def package_archive_saved
      "Pasta do pacote salva."
    end

    def certificate_installed(organization)
      "Certificado A1 de #{organization.sefaz_titular_display} instalado, válido até #{date_of(organization.sefaz_not_after)}."
    end

    def certificate_removed(titular)
      "Certificado A1 de #{titular} removido."
    end

    def bank_account_created(bank_account)
      "Conta bancária criada: #{name_of(bank_account.name)}."
    end

    def bank_account_saved(bank_account)
      "Conta bancária salva: #{name_of(bank_account.name)}."
    end

    def bank_account_deactivated(bank_account)
      "Conta bancária desativada: #{name_of(bank_account.name)}."
    end

    def bank_account_reactivated(bank_account)
      "Conta bancária reativada: #{name_of(bank_account.name)}."
    end

    def extra_exception_kind_created(kind)
      "Tipo extra criado: #{name_of(kind.name)}."
    end

    def extra_exception_kind_saved(kind)
      "Tipo extra salvo: #{name_of(kind.name)}."
    end

    def extra_exception_kind_activated(kind)
      "Tipo extra ativado: #{name_of(kind.name)}."
    end

    def extra_exception_kind_deactivated(kind)
      "Tipo extra desativado: #{name_of(kind.name)}."
    end

    def extra_exception_kind_deleted(name)
      "Tipo extra excluído: #{name_of(name)}."
    end

    def base_document_exception_changed(kind, active)
      state = active ? "reativada" : "desativada"
      "Exceção #{base_exception_name(kind)} #{state}."
    end

    private

    # A named value that cannot fit the banner keeps its beginning and says so.
    def name_of(value)
      text = value.to_s.strip
      text.length > NAME_MAX ? "#{text[0, NAME_MAX - 1]}…" : text
    end

    def money(amount_cents)
      format_reais(amount_cents)
    end

    # `ApplicationHelper#month_title` goes through the view `l` helper, which a model does not have.
    def month_title(year_month)
      I18n.l(Date.strptime(year_month, "%Y-%m"), format: :month_title)
    end

    def date_of(value)
      I18n.l(value.to_date)
    end

    def movement_counts(bank_statement)
      clauses = []
      inflows = bank_statement.inflows.count
      payments = bank_statement.payments.count
      clauses << "#{inflows} #{inflows == 1 ? "recebimento" : "recebimentos"}" if inflows.positive?
      clauses << "#{payments} #{payments == 1 ? "pagamento" : "pagamentos"}" if payments.positive?
      clauses.empty? ? "" : ": #{clauses.join(SEPARATOR)}"
    end

    def exception_label(payment)
      extra = payment.extra_exception_kind
      return extra.name if extra

      base_exception_name(payment.document_exception_kind)
    end

    def base_exception_name(kind)
      ExtraExceptionKind::BASE_OFFER_KINDS.key(kind.to_s) || kind.to_s
    end
  end
end
