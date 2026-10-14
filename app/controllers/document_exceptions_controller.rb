class DocumentExceptionsController < ApplicationController
  SELECTION = "Selecione um pagamento para marcar a exceção."

  before_action :require_coordinator_organization

  def create
    month = find_month_with_visible_movements
    return unless month

    payment = if matches_screen?
      selected_missing_payment(month)
    else
      payment_on(month)
    end
    return unless payment

    extra_id = params[:extra_exception_kind_id].presence
    if extra_id && focused_organization.extra_exception_kinds.find_by(id: extra_id).nil?
      head :not_found
      return
    end

    payment.mark_document_exception(params[:kind], extra_exception_kind_id: extra_id)
    if payment.errors.empty?
      redirect_to after_month_mutate_path(month), status: :found
    else
      render_after_month_mutate(month, payment.errors[:base].first)
    end
  end

  def destroy
    month = find_month_with_visible_movements
    return unless month

    payment = payment_on(month)
    return unless payment

    payment.unmark_document_exception
    if payment.errors.empty?
      redirect_to after_month_mutate_path(month), status: :found
    else
      render_after_month_mutate(month, payment.errors[:base].first)
    end
  end

  private

  def payment_on(month)
    payment = Payment.joins(:bank_statement).find_by(id: params[:id], bank_statements: { month_id: month.id })
    unless payment
      head :not_found
      return
    end

    payment
  end

  def selected_missing_payment(month)
    return unless assign_matches_account_filter

    ids = Array(params[:payment_ids]).map(&:to_i).reject(&:zero?).uniq
    if ids.size != 1
      render_after_month_mutate(month, SELECTION)
      return
    end

    payment = Payment.joins(:bank_statement).find_by(id: ids.first, bank_statements: { month_id: month.id })
    unless payment
      head :not_found
      return
    end

    payment
  end
end
