class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_account

  helper_method :current_account, :focused_organization

  private

  def current_account
    return unless session[:account_id]

    @current_account ||= Account.find_by(id: session[:account_id])
  end

  def focused_organization
    return unless current_account && session[:organization_id]

    @focused_organization ||= current_account.coordinator_organizations.find_by(id: session[:organization_id])
  end

  def require_account
    redirect_to login_path, status: :found unless current_account
  end

  def load_home
    @organization = focused_organization
    @coordinator_accesses = @organization.accesses.coordinator.includes(:account).order("accounts.email")
    @invites = @organization.invites.order(:email)
    @focusable_organizations = current_account.coordinator_organizations.order(:name)
  end

  def sign_in(account, organization:)
    reset_session
    session[:account_id] = account.id
    session[:organization_id] = organization.id
  end
end
