class OrganizationsController < ApplicationController
  before_action :require_focused_organization

  def show
    if coordinator_on_focus?
      load_home
    else
      @organization = focused_organization
    end
  end
end
