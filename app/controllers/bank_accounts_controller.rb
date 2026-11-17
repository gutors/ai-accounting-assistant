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
      redirect_success("/setup", ActionToast.bank_account_created(bank_account))
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

    was_active = bank_account.active?
    if bank_account.apply_from(bank_account_params)
      redirect_success("/setup", bank_account_toast(bank_account, was_active))
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

  # The flag the person flipped is the outcome worth naming; a plain field save is just a save.
  def bank_account_toast(bank_account, was_active)
    return ActionToast.bank_account_saved(bank_account) if bank_account.active? == was_active

    bank_account.active? ? ActionToast.bank_account_reactivated(bank_account) : ActionToast.bank_account_deactivated(bank_account)
  end
end
