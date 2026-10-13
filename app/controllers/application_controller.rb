class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_account
  before_action :repair_stale_focus
  after_action :repair_stale_focus

  helper_method :current_account, :focused_organization, :coordinator_on_focus?, :administrator?

  private

  def current_account
    return unless session[:account_id]

    @current_account ||= Account.find_by(id: session[:account_id])
  end

  def focused_organization
    return unless current_account && session[:organization_id]

    @focused_organization ||= current_account.organizations.find_by(id: session[:organization_id])
  end

  def coordinator_on_focus?
    return false unless current_account && focused_organization

    current_account.coordinator_accesses.exists?(organization_id: focused_organization.id)
  end

  def administrator?
    allow = NormalizedEmail.normalize(ENV["ADMINISTRATOR_EMAIL"])
    allow.present? && current_account&.email == allow
  end

  def require_account
    redirect_to login_path, status: :found unless current_account
  end

  def repair_stale_focus
    return unless current_account
    return if session[:organization_id].blank?
    return if current_account.organizations.exists?(id: session[:organization_id])

    session[:organization_id] = current_account.organization_for_focus&.id
    @focused_organization = nil
  end

  def require_focused_organization
    redirect_to login_path, status: :found unless focused_organization
  end

  def require_coordinator_organization
    unless focused_organization
      redirect_to login_path, status: :found
      return
    end

    head :not_found unless coordinator_on_focus?
  end

  def load_documents
    scope = focused_organization.supporting_documents.listed.includes(:month, :match, :justification)
    scope = scope.where(account: current_account) unless coordinator_on_focus?
    @documents = scope
    justifications = focused_organization.justifications.includes(:supporting_documents).order(created_at: :desc, id: :desc)
    justifications = justifications.where(account: current_account) unless coordinator_on_focus?
    @justifications = justifications
  end

  def load_home
    @organization = focused_organization
    @coordinator_accesses = @organization.home_coordinator_accesses
    @submitter_accesses = @organization.accesses.submitter.includes(:account).order("accounts.email")
    @invites = @organization.invites.order(:email)
    @focusable_organizations = current_account.organizations.order(:name)
    @months = @organization.months.order(year_month: :desc)
  end

  def deliver_invite(invite)
    message = if invite.submitter?
      InviteMailer.submitter_invite(invite)
    else
      InviteMailer.coordinator_invite(invite)
    end
    message.deliver_now
    invite.update!(last_delivery: :sent)
    true
  rescue StandardError
    invite.update!(last_delivery: :failed)
    false
  end

  def find_focused_month
    unless Month.valid_year_month?(params[:year_month])
      head :not_found
      return
    end

    month = focused_organization.months.find_by(year_month: params[:year_month])
    unless month
      head :not_found
      return
    end

    month
  end

  def find_month_with_visible_movements
    month = find_focused_month
    return unless month

    unless month.accounts_confirmed? || month.closed?
      head :not_found
      return
    end

    month
  end

  def load_month_page
    @organization = focused_organization
    @active_bank_accounts = @organization.bank_accounts.where(active: true).includes(:bank).order(:name)
    @statements_by_account_id = @month.bank_statements.with_attached_pdf.with_attached_spreadsheet.index_by(&:bank_account_id)
    @inflows = Inflow.joins(:bank_statement).where(bank_statements: { month_id: @month.id }).includes(bank_statement: :bank_account).order(:occurred_on, :id)
    @payments = Payment.joins(:bank_statement).where(bank_statements: { month_id: @month.id }).includes(:extra_exception_kind, match: :supporting_documents, bank_statement: :bank_account).order(:occurred_on, :id)
    @active_extra_exception_kinds = @organization.extra_exception_kinds.where(active: true).order(:name)
    @unmatched_documents = @organization.supporting_documents.unmatched.listed.where(
      month_id: @month.closed? ? @month.id : [ nil, @month.id ]
    )
    @missing_document_payments = @payments.select(&:missing_document?)
    @suggestions_by_payment_id = suggestions_on_month
    @exception_suggestions_by_payment_id = exception_suggestions_on_month
    @format_2_suggestion = format_2_suggestion_on_month
    @focusable_organizations = current_account.organizations.order(:name)
  end

  def load_setup
    @organization = focused_organization
    @banks = Bank.ordered_catalog
    @bank_accounts = @organization.bank_accounts.includes(:bank).order(:name)
    @extra_exception_kinds = @organization.extra_exception_kinds.order(:name)
    @focusable_organizations = current_account.organizations.order(:name)
    assign_editing_bank_account_from_query unless instance_variable_defined?(:@editing_bank_account)
    prepare_bank_account_form
  end

  def assign_editing_bank_account_from_query
    return unless params[:edit] == "bank_account"

    @editing_bank_account = @organization.bank_accounts.find_by(id: params[:bank_account_id])
  end

  def assign_bank_account_form_from_params
    @bank_account_form = {
      name: params[:name].to_s,
      compe: params[:compe],
      coordinates: params[:coordinates].to_s
    }
  end

  def prepare_bank_account_form
    editing = @editing_bank_account
    @bank_account_form ||= {
      name: editing&.name.to_s,
      compe: editing&.bank&.compe,
      coordinates: editing&.coordinates.to_s
    }
  end

  def suggestions_on_month
    return {} if @month.closed?

    match_proposals_for_page.each_with_object({}) do |proposal, index|
      proposal.payments.each do |payment|
        next unless payment.bank_statement.month_id == @month.id

        index[payment.id] = proposal
      end
    end
  end

  def exception_suggestions_on_month
    return {} if @month.closed?

    ExceptionSuggestion.assign(@organization, match_proposals: match_proposals_for_page).each_with_object({}) do |proposal, index|
      next unless proposal.payment.bank_statement.month_id == @month.id

      index[proposal.payment.id] = proposal
    end
  end

  def format_2_suggestion_on_month
    Suggestion.format_2_for_n1_form(@suggestions_by_payment_id.values)
  end

  def match_proposals_for_page
    @match_proposals_for_page ||= Suggestion.assign(@organization)
  end

  def sign_in(account, organization:)
    reset_session
    session[:account_id] = account.id
    session[:organization_id] = organization&.id
  end

  def redirect_success(path)
    redirect_with_toast(path, kind: "success", message: "Pronto.")
  end

  def redirect_after_invite_mail(invite)
    if deliver_invite(invite)
      redirect_success(root_path)
    else
      redirect_with_toast(root_path, kind: "error", message: "O convite foi gravado, mas o e-mail não saiu.")
    end
  end

  def redirect_with_toast(path, kind:, message:)
    flash[:toast] = message
    flash[:toast_kind] = kind
    redirect_to path, status: :found
  end

  def toast_now(kind:, message:)
    return if message.blank?

    flash.now[:toast] = message
    flash.now[:toast_kind] = kind
  end

  def turbo_stream_refusal?
    request.accept.to_s.include?("text/vnd.turbo-stream.html")
  end

  def render_refusal_streams(message)
    render turbo_stream: [
      turbo_stream.action_all(
        :replace,
        "[data-notice=error]",
        partial: "shared/notice",
        locals: { message: message }
      ),
      turbo_stream.update(
        "toast-host",
        partial: "shared/toast",
        locals: { toast: message, toast_kind: "error" }
      )
    ], status: :unprocessable_content
  end
end
