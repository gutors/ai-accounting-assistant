class BankStatementsController < ApplicationController
  before_action :require_coordinator_organization

  def create
    unless Month.valid_year_month?(params[:year_month])
      head :not_found
      return
    end

    month = focused_organization.months.find_by(year_month: params[:year_month])
    unless month
      head :not_found
      return
    end

    bank_account = focused_organization.bank_accounts.find_by(id: params[:bank_account_id])
    unless bank_account&.active?
      head :not_found
      return
    end

    statement = BankStatement.import(
      month: month,
      bank_account: bank_account,
      pdf: params[:pdf],
      spreadsheet: params[:spreadsheet]
    )

    if statement.errors.empty?
      redirect_to "/months/#{month.year_month}", status: :found
    else
      @month = month
      @import_error = statement.errors[:base].first
      @import_bank_account_id = bank_account.id
      load_month_page
      render "months/show", status: :unprocessable_content
    end
  end
end
