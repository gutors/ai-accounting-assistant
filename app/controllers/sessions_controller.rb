class SessionsController < ApplicationController
  skip_before_action :require_account, only: %i[new denied]

  def new
    @local_operator_accounts = local_operator_accounts if Rails.env.development?
  end

  def denied
  end

  def destroy
    reset_session
    redirect_to login_path, status: :found
  end

  private

  def local_operator_accounts
    admin = NormalizedEmail.normalize(ENV["ADMINISTRATOR_EMAIL"])
    Account.includes(:accesses).order(:email).select do |account|
      account.accesses.any? || (admin.present? && account.email == admin)
    end
  end
end
