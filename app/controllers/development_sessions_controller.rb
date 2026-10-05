class DevelopmentSessionsController < ApplicationController
  skip_before_action :require_account

  def create
    unless Rails.env.local?
      head :not_found
      return
    end

    email = NormalizedEmail.normalize(params[:email])
    account = Account.find_by(email: email)
    organization = account&.organization_for_focus

    if account.nil? || (organization.nil? && !local_administrator?(account))
      redirect_to denied_path, status: :found
      return
    end

    sign_in(account, organization: organization)
    redirect_to(organization ? root_path : administration_path, status: :found)
  end

  private

  def local_administrator?(account)
    allow = NormalizedEmail.normalize(ENV["ADMINISTRATOR_EMAIL"])
    allow.present? && account.email == allow
  end
end
