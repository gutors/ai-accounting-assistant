class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_account
  before_action :repair_stale_focus
  before_action :assign_focusable_organizations
  after_action :repair_stale_focus

  helper_method :current_account, :focused_organization, :coordinator_on_focus?, :administrator?,
    :people_desk_path, :setup_item_path

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
    base_scope = focused_organization.supporting_documents.unmatched.includes(:month, :justification)
    base_scope = base_scope.where(account: current_account) unless coordinator_on_focus?
    @list_filters = document_list_filters
    @documents = base_scope.filter_list(**@list_filters)
    @justifiable_documents = base_scope.listed.where(month_id: nil, justification_id: nil) unless coordinator_on_focus?
    justifications = focused_organization.justifications.includes(:supporting_documents).order(created_at: :desc, id: :desc)
    justifications = justifications.where(account: current_account) unless coordinator_on_focus?
    @justifications = justifications
  end

  def document_list_filters
    query = request.query_parameters
    {
      q: query[:q].to_s.strip,
      kind: SupportingDocument.kinds.key?(query[:kind].to_s) ? query[:kind].to_s : "",
      date_from: SupportingDocument.parse_filter_date(query[:date_from])&.iso8601.to_s,
      date_to: SupportingDocument.parse_filter_date(query[:date_to])&.iso8601.to_s,
      sort: query[:sort].to_s == "amount" ? "amount" : "date",
      dir: query[:dir].to_s == "asc" ? "asc" : "desc"
    }
  end

  def assign_focusable_organizations
    @focusable_organizations = current_account ? current_account.organizations.order(:name) : Organization.none
  end

  def people_desk_path
    root_path(desk: "people")
  end

  def setup_item_path(item)
    "/setup?item=#{item}"
  end

  def people_desk_requested?
    return true if @people_desk

    params[:desk].to_s == "people"
  end

  def render_people_home(status:)
    @people_desk = true
    load_home
    render "organizations/show", status: status
  end

  def load_home
    @organization = focused_organization
    @coordinator_accesses = @organization.accesses.coordinator.includes(:account).order(:created_at, :id)
    @submitter_accesses = @organization.accesses.submitter.includes(:account).order(:created_at, :id)
    @coordinator_invites = @organization.invites.coordinator.order(:created_at, :id)
    @submitter_invites = @organization.invites.submitter.order(:created_at, :id)
    @invites = @organization.invites.order(:created_at, :id)
    @failed_invite_count = @organization.invites.where(last_delivery: :failed).count
    @people_desk = people_desk_requested?
    @months = @organization.months.order(year_month: :desc).includes(:bank_statements)
    @active_bank_account_ids = @organization.bank_accounts.where(active: true).pluck(:id)
    @in_work_month = @months.find { |month| !month.closed? }
    @selected_month = selected_month_from_params || @in_work_month
    return unless @selected_month

    @active_bank_accounts = @organization.bank_accounts.where(active: true).joins(:bank).includes(:bank)
      .order("banks.presentation_name", "bank_accounts.name")
    @statements_by_account_id = @selected_month.bank_statements.index_by(&:bank_account_id)
    return unless @selected_month.accounts_confirmed?

    @missing_document_count = Payment.without_catalog(
      Payment.joins(:bank_statement)
        .where(bank_statements: { month_id: @selected_month.id })
        .missing_document
        .includes(bank_statement: { bank_account: :bank })
    ).size
  end

  def selected_month_from_params
    year_month = params[:year_month].to_s
    return if year_month.blank?

    @months.find { |month| month.year_month == year_month }
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

  def matches_screen?
    params[:screen].to_s == "matches"
  end

  def assign_matches_account_filter
    raw = params[:bank_account_id]
    if raw.blank?
      @bank_account_id = nil
      return true
    end

    account = focused_organization.bank_accounts.find_by(id: raw, active: true)
    unless account
      head :not_found
      return false
    end

    @bank_account_id = account.id
    true
  end

  def load_matches_page
    load_month_page
    apply_bank_account_movement_filter
    @unmatched_documents = @unmatched_documents.sort_by { |document| [ document.document_on, document.id ] }
    @next_suggestion_payment = @missing_document_payments.min_by { |payment| [ payment.occurred_on, payment.id ] }
    @next_match_proposal = @suggestions_by_payment_id[@next_suggestion_payment&.id]
    @confirmed_matches = @payments.filter_map(&:match).uniq(&:id)
    @marked_exceptions = @payments.reject { |payment| payment.missing_document? || payment.match_id.present? }
  end

  def apply_bank_account_movement_filter
    return unless @bank_account_id

    @payments = @payments.select { |payment| payment.bank_statement.bank_account_id == @bank_account_id }
    @missing_document_payments = @payments.select(&:missing_document?)
    @inflows = @inflows.select { |inflow| inflow.bank_statement.bank_account_id == @bank_account_id }
  end

  def after_month_mutate_path(month)
    return "/months/#{month.year_month}" unless matches_screen?

    path = "/months/#{month.year_month}/matches"
    id = @bank_account_id || params[:bank_account_id].presence
    id.present? ? "#{path}?bank_account_id=#{id}" : path
  end

  def render_after_month_mutate(month, message)
    @month = month
    @month_error = message
    if matches_screen?
      return unless assign_matches_account_filter

      load_matches_page
      render "matches/show", status: :unprocessable_content
    else
      load_month_page
      render "months/show", status: :unprocessable_content
    end
  end

  def load_month_page
    @organization = focused_organization
    @active_bank_accounts = @organization.bank_accounts.where(active: true).includes(:bank).order(:name)
    @statements_by_account_id = @month.bank_statements.with_attached_pdf.with_attached_spreadsheet.index_by(&:bank_account_id)
    @inflows = Inflow.joins(:bank_statement).where(bank_statements: { month_id: @month.id }).includes(bank_statement: :bank_account).order(:occurred_on, :id).to_a
    @payments = Payment.without_catalog(
      Payment.joins(:bank_statement).where(bank_statements: { month_id: @month.id })
        .includes(:extra_exception_kind, match: :supporting_documents, bank_statement: { bank_account: :bank })
        .order(:occurred_on, :id)
    )
    @active_extra_exception_kinds = @organization.extra_exception_kinds.where(active: true).order(:name)
    @unmatched_documents = @organization.supporting_documents.unmatched.listed.with_attached_photo.where(
      month_id: @month.closed? ? @month.id : [ nil, @month.id ]
    ).to_a
    @payments_sort, @payments_dir = MonthListSort.parse(params[:payments_sort], params[:payments_dir], columns: %w[date amount])
    @inflows_sort, @inflows_dir = MonthListSort.parse(params[:inflows_sort], params[:inflows_dir], columns: %w[date amount])
    @pool_sort, @pool_dir = MonthListSort.parse(params[:pool_sort], params[:pool_dir], columns: %w[date payee amount])
    @payments = MonthListSort.apply(@payments, @payments_sort, @payments_dir, date: :occurred_on)
    @inflows = MonthListSort.apply(@inflows, @inflows_sort, @inflows_dir, date: :occurred_on)
    @unmatched_documents = MonthListSort.apply(@unmatched_documents, @pool_sort, @pool_dir, date: :document_on, payee: :payee)
    @missing_document_payments = @payments.select(&:missing_document?)
    @suggestions_by_payment_id = suggestions_on_month
    @exception_suggestions_by_payment_id = exception_suggestions_on_month
    @format_2_suggestion = format_2_suggestion_on_month
    if !@month.accounts_confirmed? && !@month.closed? && !@month.spreadsheet_present?
      @month_error ||= Month::CONFIRM_NEEDS_SPREADSHEET
    end
  end

  def load_setup
    @organization = focused_organization
    @banks = Bank.ordered_catalog
    @bank_accounts = @organization.bank_accounts.includes(:bank).order(:name)
    @extra_exception_kinds = @organization.extra_exception_kinds.order(:name)
    assign_editing_bank_account_from_query unless instance_variable_defined?(:@editing_bank_account)
    prepare_bank_account_form
    @setup_desk = SetupDesk.new(
      @organization,
      bank_accounts: @bank_accounts,
      extra_exception_kinds: @extra_exception_kinds,
      item: params[:item],
      edit: params[:edit],
      forced_item: @setup_item
    )
    @setup_item = @setup_desk.selected
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

  def redirect_success(path, message)
    redirect_with_toast(path, kind: "success", message: message)
  end

  def redirect_after_invite_mail(invite, sent_message:)
    if deliver_invite(invite)
      redirect_success(people_desk_path, sent_message)
    else
      redirect_with_toast(people_desk_path, kind: "error", message: "O convite foi gravado, mas o e-mail não saiu.")
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
