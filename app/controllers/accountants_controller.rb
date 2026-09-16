class AccountantsController < ApplicationController
  def update
    unless focused_organization
      redirect_to login_path, status: :found
      return
    end

    if focused_organization.update_accountant(accountant_params)
      redirect_to "/setup", status: :found
    else
      load_setup
      render "setup/show", status: :unprocessable_content
    end
  end

  private

  def accountant_params
    params.permit(:presentation_name, :tax_id, :legal_name, :pix_key, :destination_email)
  end
end
