class MonthReturnsController < ApplicationController
  before_action :require_coordinator_organization

  def create
    month = find_month
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

    document.return_to_no_month
    if document.errors.empty?
      redirect_to "/months/#{month.year_month}", status: :found
    else
      @month = month
      @month_error = document.errors[:base].first
      load_month_page
      render "months/show", status: :unprocessable_content
    end
  end

  private

  def find_month
    unless Month.valid_year_month?(params[:year_month])
      head :not_found
      return
    end

    month = focused_organization.months.find_by(year_month: params[:year_month])
    unless month
      head :not_found
      return
    end

    month
  end
end
