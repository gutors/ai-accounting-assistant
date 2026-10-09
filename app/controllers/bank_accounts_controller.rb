class BankAccountsController < ApplicationController
  before_action :require_coordinator_organization

  def create
    bank_account = BankAccount.create_for(
      organization: focused_organization,
      name: params[:name],
      compe: params[:compe],
      coordinates: params[:coordinates]
    )

    if bank_account.persisted?
      redirect_success("/setup")
    else
      load_setup
      assign_bank_account_form_from_params
      prepare_bank_account_form
      @bank_account_form_open = true
      render "setup/show", status: :unprocessable_content
    end
  end

  def update
    bank_account = focused_organization.bank_accounts.find_by(id: params[:id])
    unless bank_account
      head :not_found
      return
    end

    if bank_account.apply_from(bank_account_params)
      redirect_success("/setup")
    else
      editing_id = bank_account.id
      bank_account.reload
      load_setup
      @editing_bank_account = @organization.bank_accounts.find(editing_id)
      assign_bank_account_form_from_params
      prepare_bank_account_form
      render "setup/show", status: :unprocessable_content
    end
  end

  private

  def bank_account_params
    params.permit(:name, :compe, :coordinates, :active)
  end
end
