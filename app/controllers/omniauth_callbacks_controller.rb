class OmniauthCallbacksController < ApplicationController
  skip_before_action :require_account
  skip_forgery_protection

  def google_oauth2
    result = OperatorAuthenticator.call(request.env["omniauth.auth"])

    case result.status
    when :signed_in
      sign_in(result.account, organization: result.organization)
      redirect_to root_path, status: :found
    when :denied
      redirect_to denied_path, status: :found
    else
      redirect_to login_path, status: :found
    end
  end

  def failure
    redirect_to login_path, status: :found
  end
end
