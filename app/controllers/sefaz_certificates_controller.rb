class SefazCertificatesController < ApplicationController
  skip_before_action :require_account, only: :show
  before_action :require_coordinator_organization, except: :show

  def show
    head :not_found
  end

  def create
    if focused_organization.install_sefaz_certificate(file: params[:certificate], passphrase: params[:passphrase])
      redirect_to "/setup", status: :found
    else
      load_setup
      @certificate_error = focused_organization.errors[:base].first
      render "setup/show", status: :unprocessable_content
    end
  end

  def destroy
    focused_organization.remove_sefaz_certificate
    redirect_to "/setup", status: :found
  end
end
