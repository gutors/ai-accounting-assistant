class MonthReturnsController < ApplicationController
  before_action :require_coordinator_organization

  def create
    month = find_month_with_visible_movements
    return unless month

    document = focused_organization.supporting_documents.find_by(
      id: params[:id],
      month_id: month.id,
      match_id: nil
    )
    unless document
      head :not_found
      return
    end

    payee = document.payee
    document.return_to_no_month
    if document.errors.empty?
      redirect_success("/months/#{month.year_month}", ActionToast.document_returned(payee))
    else
      @month = month
      @month_error = document.errors[:base].first
      load_month_page
      render "months/show", status: :unprocessable_content
    end
  end
end
