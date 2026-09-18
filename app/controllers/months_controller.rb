class MonthsController < ApplicationController
  before_action :require_coordinator_organization

  def create
    month = Month.open(organization: focused_organization, year_month: params[:year_month])
    if month.persisted?
      redirect_to "/months/#{month.year_month}", status: :found
    else
      load_home
      render "organizations/show", status: :unprocessable_content
    end
  end

  def show
    month = find_month
    return unless month

    @month = month
    load_month_page
  end

  def close
    month = find_month
    return unless month

    ids = Array(params[:supporting_document_ids]).map(&:to_i).reject(&:zero?).uniq
    documents = focused_organization.supporting_documents.where(id: ids)
    if ids.any? && documents.size != ids.size
      head :not_found
      return
    end

    month.close_for_send(supporting_documents: documents.to_a)
    if month.errors.empty?
      redirect_to "/months/#{month.year_month}", status: :found
    else
      @month = month
      @month_error = month.errors[:base].first
      load_month_page
      render :show, status: :unprocessable_content
    end
  end

  def restore
    month = find_month
    return unless month

    month.restore_month_folder
    if month.errors.empty?
      redirect_to "/months/#{month.year_month}", status: :found
    else
      @month = month
      @month_error = month.errors[:base].first
      load_month_page
      render :show, status: :unprocessable_content
    end
  end

  def reopen
    month = find_month
    return unless month

    month.reopen
    if month.errors.empty?
      redirect_to "/months/#{month.year_month}", status: :found
    else
      @month = month
      @month_error = month.errors[:base].first
      load_month_page
      render :show, status: :unprocessable_content
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
