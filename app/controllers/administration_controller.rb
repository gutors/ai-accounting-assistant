class AdministrationController < ApplicationController
  before_action :require_administrator
  before_action :prepare_administration

  def show
    load_registration
  end

  def new
    load_registration
  end

  def edit
    @organization = Organization.find_by(id: params[:id])
    unless @organization
      head :not_found
      return
    end

    load_registration
    load_name_draft
    load_email_draft
  end

  def create
    session.delete(:administration_name)
    session.delete(:administration_email)
    @name = params[:name].to_s
    @email = params[:email].to_s
    @notices = registration_notices(@name, @email)
    if @notices.any?
      render :new, status: :unprocessable_content
      return
    end

    session[:administration_pending] = {
      "name" => @name.strip,
      "email" => NormalizedEmail.normalize(@email),
      "confirming" => true
    }
    redirect_to_new_administration
  end

  def confirm
    pending = pending_registration
    unless pending
      redirect_to administration_path, status: :found
      return
    end

    organization = Organization.register_coordinator(name: pending["name"], email: pending["email"])
    account = Account.find_by!(email: pending["email"])
    session.delete(:administration_pending)
    session[:organization_id] = organization.id if current_account.email == pending["email"]
    session[:administration_result] = registration_result_for(organization, account, deliver_welcome(organization, account))
    redirect_to administration_path, status: :found
  rescue ActiveRecord::RecordNotUnique => error
    raise unless error.message.include?("index_organizations_on_lower_name")

    @name = pending["name"]
    @email = pending["email"]
    @notices = [ "Já existe uma organização com esse nome." ]
    render :new, status: :unprocessable_content
  end

  def correct
    demote_confirmations
    redirect_after_correct
  end

  def mail
    result = registration_result
    unless result
      redirect_to administration_path, status: :found
      return
    end

    organization = Organization.find_by(id: result["organization_id"])
    account = Account.find_by(email: result["email"])
    unless organization && account
      redirect_to administration_path, status: :found
      return
    end

    session[:administration_result] = result.merge("mail_sent" => deliver_welcome(organization, account))
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
    session.delete(:administration_email)
    session[:administration_name] = {
      "organization_id" => organization.id,
      "name" => organization.name,
      "confirming" => false
    }
    redirect_to_edit(organization)
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
    if @notices.any?
      @organization = organization
      load_registration
      load_name_draft
      render :edit, status: :unprocessable_content
      return
    end

    redirect_to_edit(organization)
  end

  def name_cancel
    organization = name_draft_organization
    session.delete(:administration_name)
    organization ? redirect_to_edit(organization) : redirect_to_administration
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
    @organization = organization
    load_registration
    load_name_draft
    render :edit, status: :unprocessable_content
  end

  def email_open
    organization = Organization.find_by(id: params[:organization_id])
    access = coordinator_access_for(organization, params[:email])
    unless access
      head :not_found
      return
    end

    session.delete(:administration_pending)
    session.delete(:administration_name)
    session[:administration_email] = {
      "organization_id" => organization.id,
      "from_email" => access.account.email,
      "email" => access.account.email,
      "confirming" => false
    }
    redirect_to_edit(organization)
  end

  def email_continue
    organization = email_draft_organization
    unless organization
      redirect_to administration_path, status: :found
      return
    end

    typed = params[:email].to_s
    @notices = email_notices(typed, organization, except_email: email_draft_session["from_email"])
    session[:administration_email] = email_draft_session.merge(
      "email" => @notices.any? ? typed : NormalizedEmail.normalize(typed),
      "confirming" => @notices.empty?
    )
    if @notices.any?
      @organization = organization
      load_registration
      load_email_draft
      render :edit, status: :unprocessable_content
      return
    end

    redirect_to_edit(organization)
  end

  def email_cancel
    organization = email_draft_organization
    session.delete(:administration_email)
    organization ? redirect_to_edit(organization) : redirect_to_administration
  end

  def email_confirm
    organization = Organization.find_by(id: params[:organization_id])
    unless organization
      head :not_found
      return
    end

    draft = email_draft_session
    access = coordinator_access_for(organization, draft&.dig("from_email"))
    unless email_confirmation_for?(draft, organization) && access
      redirect_to administration_path, status: :found
      return
    end

    account = organization.replace_coordinator(access: access, email: draft["email"])
    session.delete(:administration_email)
    session[:organization_id] = organization.id if current_account.email == account.email
    session[:administration_result] = {
      "organization_id" => organization.id,
      "mail_sent" => deliver_welcome(organization, account),
      "email" => account.email,
      "kind" => "correction"
    }
    redirect_to administration_path, status: :found
  end

  def destroy
    organization = Organization.find_by(id: params[:organization_id])
    unless organization
      head :not_found
      return
    end

    unless organization.remove
      @organization = organization
      @removal_organization = organization
      load_registration
      load_name_draft
      load_email_draft
      render :edit, status: :unprocessable_content
      return
    end

    redirect_to administration_path, status: :found
  end

  private

  def require_administrator
    head :not_found unless administrator?
  end

  def prepare_administration
    @organizations = Organization.order(:name).includes(accesses: :account)
    @notices = []
    @name = ""
    @email = ""
  end

  def redirect_to_administration
    redirect_to administration_path, status: :see_other
  end

  def redirect_to_new_administration
    redirect_to new_administration_path, status: :see_other
  end

  def redirect_to_edit(organization)
    redirect_to edit_administration_path(organization), status: :see_other
  end

  def redirect_after_correct
    name_org = name_draft_organization
    email_org = email_draft_organization
    if name_org
      redirect_to_edit(name_org)
    elsif email_org
      redirect_to_edit(email_org)
    elsif pending_registration
      redirect_to_new_administration
    else
      redirect_to_administration
    end
  end

  def demote_confirmations
    [ :administration_pending, :administration_name, :administration_email ].each do |key|
      draft = session[key]
      draft["confirming"] = false if draft.is_a?(Hash)
    end
  end

  def load_registration
    @pending = pending_registration
    @result = registration_result
    @result_organization = Organization.find_by(id: @result["organization_id"]) if @result
    @name = @pending&.dig("name").to_s
    @email = @pending&.dig("email").to_s
    @registration_confirmation = @pending&.dig("confirming")
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

  def load_email_draft
    draft = email_draft_session
    @email_organization = Organization.find_by(id: draft["organization_id"]) if draft
    unless @email_organization
      @email_phase = nil
      return
    end

    @email_from = draft["from_email"].to_s
    @email_value = draft["email"].to_s
    @email_phase = draft["confirming"] ? :confirm : :field
  end

  def name_draft_organization
    draft = name_draft_session
    Organization.find_by(id: draft["organization_id"]) if draft
  end

  def email_draft_organization
    draft = email_draft_session
    Organization.find_by(id: draft["organization_id"]) if draft
  end

  def name_confirmation_for?(draft, organization)
    draft && draft["confirming"] && draft["name"].present? &&
      draft["organization_id"].to_s == organization.id.to_s
  end

  def email_confirmation_for?(draft, organization)
    draft && draft["confirming"] && draft["email"].present? &&
      draft["organization_id"].to_s == organization.id.to_s
  end

  def name_draft_session
    draft = session[:administration_name]
    return unless draft.is_a?(Hash) && draft["organization_id"].present?

    draft
  end

  def email_draft_session
    draft = session[:administration_email]
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

  def registration_result_for(organization, account, mail_sent)
    {
      "organization_id" => organization.id,
      "mail_sent" => mail_sent,
      "email" => account.email,
      "kind" => "registration"
    }
  end

  def coordinator_access_for(organization, email)
    return unless organization

    normalized = NormalizedEmail.normalize(email)
    return if normalized.blank?

    organization.accesses.coordinator.joins(:account).find_by(accounts: { email: normalized })
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

  def email_notices(email, organization, except_email:)
    notices = []
    unless NormalizedEmail.valid?(email)
      notices << "Informe um e-mail válido."
      return notices
    end

    normalized = NormalizedEmail.normalize(email)
    except = NormalizedEmail.normalize(except_email)
    if normalized != except && organization.accesses.joins(:account).exists?(accounts: { email: normalized })
      notices << "Esse e-mail já tem acesso a esta organização."
    end
    notices
  end

  def deliver_welcome(organization, account)
    CoordinatorWelcomeMailer.welcome(organization, account).deliver_now
    true
  rescue StandardError
    false
  end
end
