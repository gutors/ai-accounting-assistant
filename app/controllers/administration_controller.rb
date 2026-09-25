class AdministrationController < ApplicationController
  before_action :require_administrator
  before_action :prepare_administration

  def show
    load_registration
    load_name_draft
    return unless request.get? && @name_phase == :confirm

    session[:administration_name]["confirming"] = false
    @name_phase = :field
  end

  def create
    session.delete(:administration_name)
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
    @registration_confirmation = true
    @notices = []
    render :show
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

  def name_open
    organization = Organization.find_by(id: params[:organization_id])
    unless organization
      head :not_found
      return
    end

    session.delete(:administration_pending)
    session[:administration_name] = {
      "organization_id" => organization.id,
      "name" => organization.name,
      "confirming" => false
    }
    load_registration
    load_name_draft
    render :show
  end

  def name_continue
    organization = name_draft_organization
    unless organization
      redirect_to administration_path, status: :found
      return
    end

    typed = params[:name].to_s
    @notices = name_notices(typed, organization)
    session[:administration_name] = {
      "organization_id" => organization.id,
      "name" => @notices.any? ? typed : typed.strip,
      "confirming" => @notices.empty?
    }
    load_registration
    load_name_draft
    status = @notices.any? ? :unprocessable_content : :ok
    render :show, status: status
  end

  def name_cancel
    session.delete(:administration_name)
    redirect_to administration_path, status: :found
  end

  def name_confirm
    organization = Organization.find_by(id: params[:organization_id])
    unless organization
      head :not_found
      return
    end

    draft = name_draft_session
    unless name_confirmation_for?(draft, organization)
      redirect_to administration_path, status: :found
      return
    end

    organization.update!(name: draft["name"])
    session.delete(:administration_name)
    redirect_to administration_path, status: :found
  rescue ActiveRecord::RecordNotUnique => error
    raise unless error.message.include?("index_organizations_on_lower_name")

    session[:administration_name]["confirming"] = false
    @notices = [ "Já existe uma organização com esse nome." ]
    load_registration
    load_name_draft
    render :show, status: :unprocessable_content
  end

  private

  def require_administrator
    head :not_found unless administrator?
  end

  def prepare_administration
    @organizations = Organization.order(:name)
    @notices = []
    @name = ""
    @email = ""
  end

  def load_registration
    @pending = pending_registration
    @result = registration_result
    @result_organization = Organization.find_by(id: @result["organization_id"]) if @result
    @name = @pending&.dig("name").to_s
    @email = @pending&.dig("email").to_s
  end

  def load_name_draft
    draft = name_draft_session
    @name_organization = Organization.find_by(id: draft["organization_id"]) if draft
    unless @name_organization
      @name_phase = nil
      return
    end

    @name_value = draft["name"].to_s
    @name_phase = draft["confirming"] ? :confirm : :field
  end

  def name_draft_organization
    draft = name_draft_session
    Organization.find_by(id: draft["organization_id"]) if draft
  end

  def name_confirmation_for?(draft, organization)
    draft && draft["confirming"] && draft["name"].present? &&
      draft["organization_id"].to_s == organization.id.to_s
  end

  def name_draft_session
    draft = session[:administration_name]
    return unless draft.is_a?(Hash) && draft["organization_id"].present?

    draft
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

  def name_notices(name, organization)
    notices = []
    notices << "Informe o nome da organização." if name.strip.blank?
    if name.strip.present? && Organization.name_taken?(name, except: organization)
      notices << "Já existe uma organização com esse nome."
    end
    notices
  end

  def deliver_welcome(organization)
    CoordinatorWelcomeMailer.welcome(organization).deliver_now
    true
  rescue StandardError
    false
  end
end
