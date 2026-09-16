class BankAccountsController < ApplicationController
  def create
    unless focused_organization
      redirect_to login_path, status: :found
      return
    end

    bank_account = BankAccount.create_for(
      organization: focused_organization,
      name: params[:name],
      compe: params[:compe],
      coordinates: params[:coordinates]
    )

    if bank_account.persisted?
      redirect_to "/setup", status: :found
    else
      load_setup
      render "setup/show", status: :unprocessable_content
    end
  end

  def update
    bank_account = focused_organization&.bank_accounts&.find_by(id: params[:id])
    unless bank_account
      head :not_found
      return
    end

    if bank_account.apply_from(bank_account_params)
      redirect_to "/setup", status: :found
    else
      load_setup
      render "setup/show", status: :unprocessable_content
    end
  end

  private

  def bank_account_params
    params.permit(:name, :compe, :coordinates, :active)
  end
end
