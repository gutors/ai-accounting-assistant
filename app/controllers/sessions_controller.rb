class SessionsController < ApplicationController
  skip_before_action :require_account, only: %i[new denied]

  def new
  end

  def denied
  end

  def destroy
    reset_session
    redirect_to login_path, status: :found
  end
end
