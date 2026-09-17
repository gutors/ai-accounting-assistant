class MonthsController < ApplicationController
  def create
    unless focused_organization
      redirect_to login_path, status: :found
      return
    end

    month = Month.open(organization: focused_organization, year_month: params[:year_month])
    if month.persisted?
      redirect_to "/months/#{month.year_month}", status: :found
    else
      load_home
      render "organizations/show", status: :unprocessable_content
    end
  end

  def show
    unless focused_organization
      redirect_to login_path, status: :found
      return
    end

    month = find_month
    return unless month

    @month = month
    load_month_page
  end

  def close
    unless focused_organization
      redirect_to login_path, status: :found
      return
    end

    month = find_month
    return unless month

    month.close_for_send
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
    unless focused_organization
      redirect_to login_path, status: :found
      return
    end

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
