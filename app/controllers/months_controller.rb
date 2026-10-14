class MonthsController < ApplicationController
  before_action :require_coordinator_organization

  def create
    month = Month.open(organization: focused_organization, year_month: params[:year_month])
    if month.persisted?
      redirect_success("/months/#{month.year_month}")
    else
      load_home
      @month_error = month.errors[:base].first
      toast_now(kind: "error", message: @month_error)
      render "organizations/show", status: :unprocessable_content
    end
  end

  def account_confirmation
    month = find_month
    return unless month

    month.confirm_accounts
    if month.errors.empty?
      redirect_success("/months/#{month.year_month}")
    else
      @month = month
      @month_error = month.errors[:base].first
      render_month_show(status: :unprocessable_content)
    end
  end

  def show
    month = find_month
    return unless month

    @month = month
    render_month_show
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
      render_month_show(status: :unprocessable_content)
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
      render_month_show(status: :unprocessable_content)
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
      render_month_show(status: :unprocessable_content)
    end
  end

  def destroy
    month = find_month
    return unless month

    month.discard_never_sent
    if month.errors.empty?
      redirect_success("/")
    else
      @month_error = month.errors[:base].first
      load_home
      toast_now(kind: "error", message: @month_error)
      render "organizations/show", status: :unprocessable_content
    end
  end

  private

  def render_month_show(status: :ok)
    return unless assign_matches_account_filter

    load_month_page
    apply_bank_account_movement_filter
    render :show, status: status
  end

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
