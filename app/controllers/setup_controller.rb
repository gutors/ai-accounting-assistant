class SetupController < ApplicationController
  def show
    unless focused_organization
      redirect_to login_path, status: :found
      return
    end

    load_setup
  end
end
