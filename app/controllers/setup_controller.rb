class SetupController < ApplicationController
  before_action :require_coordinator_organization

  def show
    load_setup
  end
end
