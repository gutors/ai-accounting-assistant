class SetupController < ApplicationController
  before_action :require_coordinator_organization

  def show
    load_setup
    @accountant_editing = params[:edit] == "accountant"
  end
end
