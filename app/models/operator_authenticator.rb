class OperatorAuthenticator
  Result = Struct.new(:status, :account, :organization, keyword_init: true)

  def self.call(auth)
    new(auth).call
  end

  def initialize(auth)
    @auth = auth
  end

  def call
    return Result.new(status: :unverified) unless email_verified?

    email = NormalizedEmail.normalize(extracted_email)
    return Result.new(status: :unverified) if email.blank?

    account = Account.find_by(email: email)
    pending = Invite.where(email: email).to_a

    if pending.any?
      account ||= Account.create!(email: email, google_uid: uid.presence)
      assign_uid!(account)
      pending.each { |invite| invite.accept!(account) }
    elsif account&.accesses&.any?
      assign_uid!(account)
    else
      return Result.new(status: :denied, account: account)
    end

    Result.new(status: :signed_in, account: account, organization: focus_for(account))
  end

  private

  attr_reader :auth

  def focus_for(account)
    account.coordinator_organizations.first || account.organizations.first
  end

  def email_verified?
    values = [
      auth.dig("info", "email_verified"),
      auth.dig("extra", "raw_info", "email_verified"),
      auth.dig("extra", "id_info", "email_verified")
    ]
    values.any? { |value| value == true || value == "true" }
  end

  def extracted_email
    auth.dig("info", "email").presence || auth.dig("extra", "raw_info", "email")
  end

  def uid
    auth["uid"]
  end

  def assign_uid!(account)
    return if uid.blank? || account.google_uid.present?

    account.update!(google_uid: uid)
  end
end
