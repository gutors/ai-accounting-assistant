class AdministrationController < ApplicationController
  before_action :require_administrator

  def show
    load_registration
  end

  def create
    @name = params[:name].to_s
    @email = params[:email].to_s
    @notices = registration_notices(@name, @email)
    if @notices.any?
      render :show, status: :unprocessable_content
      return
    end

    session[:administration_pending] = {
      "name" => @name.strip,
      "email" => NormalizedEmail.normalize(@email)
    }
    @pending = session[:administration_pending]
    render :confirmation
  end

  def confirm
    pending = pending_registration
    unless pending
      redirect_to administration_path, status: :found
      return
    end

    organization = Organization.register_coordinator(name: pending["name"], email: pending["email"])
    session.delete(:administration_pending)
    session[:organization_id] = organization.id if current_account.email == pending["email"]
    session[:administration_result] = {
      "organization_id" => organization.id,
      "mail_sent" => deliver_welcome(organization)
    }
    redirect_to administration_path, status: :found
  rescue ActiveRecord::RecordNotUnique => error
    raise unless error.message.include?("index_organizations_on_lower_name")

    @name = pending["name"]
    @email = pending["email"]
    @notices = [ "Já existe uma organização com esse nome." ]
    render :show, status: :unprocessable_content
  end

  def mail
    result = registration_result
    unless result
      redirect_to administration_path, status: :found
      return
    end

    organization = Organization.find(result["organization_id"])
    session[:administration_result] = {
      "organization_id" => organization.id,
      "mail_sent" => deliver_welcome(organization)
    }
    redirect_to administration_path, status: :found
  end

  def another
    session.delete(:administration_result)
    redirect_to administration_path, status: :found
  end

  private

  def require_administrator
    head :not_found unless administrator?
  end

  def load_registration
    @pending = pending_registration
    @result = registration_result
    @organization = Organization.find_by(id: @result["organization_id"]) if @result
    @coordinator_email = coordinator_email_for(@organization)
    @name = @pending&.dig("name").to_s
    @email = @pending&.dig("email").to_s
    @notices = []
    return if @result.nil? || @result["mail_sent"] || @organization.nil?

    @notices = [ "O cadastro foi gravado, mas o e-mail não saiu." ]
  end

  def coordinator_email_for(organization)
    return if organization.nil?

    organization.accesses.coordinator.includes(:account).first&.account&.email
  end

  def pending_registration
    pending = session[:administration_pending]
    return unless pending.is_a?(Hash) && pending["name"].present? && pending["email"].present?

    pending
  end

  def registration_result
    result = session[:administration_result]
    return unless result.is_a?(Hash) && result["organization_id"].present?

    result
  end

  def registration_notices(name, email)
    notices = []
    notices << "Informe o nome da organização." if name.strip.blank?
    notices << "Informe um e-mail válido." unless NormalizedEmail.valid?(email)
    notices << "Já existe uma organização com esse nome." if name.strip.present? && Organization.name_taken?(name)
    notices
  end

  def deliver_welcome(organization)
    CoordinatorWelcomeMailer.welcome(organization).deliver_now
    true
  rescue StandardError
    false
  end
end
