class MatchesController < ApplicationController
  before_action :require_coordinator_organization

  def show
    month = find_month_with_visible_movements
    return unless month

    @month = month
    return unless assign_matches_account_filter

    load_matches_page
  end

  def create
    month = find_month_with_visible_movements
    return unless month

    payment_ids = Array(params[:payment_ids]).map(&:to_i).reject(&:zero?).uniq
    document_ids = Array(params[:supporting_document_ids]).map(&:to_i).reject(&:zero?).uniq

    payments = Payment.joins(:bank_statement).where(bank_statements: { month_id: month.id }, id: payment_ids)
    if payment_ids.any? && payments.size != payment_ids.size
      head :not_found
      return
    end

    documents = focused_organization.supporting_documents.where(id: document_ids)
    if document_ids.any? && documents.size != document_ids.size
      head :not_found
      return
    end

    match = Match.confirm(
      month: month,
      payments: payments.to_a,
      supporting_documents: documents.to_a,
      observation: params[:observation]
    )
    if match.errors.empty?
      redirect_to after_month_mutate_path(month), status: :found
    else
      render_after_month_mutate(month, match.errors[:base].first)
    end
  end

  def destroy
    month = find_month_with_visible_movements
    return unless month

    match = month.matches.find_by(id: params[:id])
    unless match
      head :not_found
      return
    end

    match.dissolve
    if match.errors.empty?
      redirect_to after_month_mutate_path(month), status: :found
    else
      render_after_month_mutate(month, match.errors[:base].first)
    end
  end
end
