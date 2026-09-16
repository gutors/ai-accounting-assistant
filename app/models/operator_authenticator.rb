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

    if account&.coordinator_accesses&.any?
      assign_uid!(account)
      Result.new(status: :signed_in, account: account, organization: account.coordinator_organizations.first)
    elsif pending.any?
      account ||= Account.create!(email: email, google_uid: uid.presence)
      assign_uid!(account)
      organization = nil
      pending.each do |invite|
        invite.accept!(account)
        organization = invite.organization
      end
      Result.new(status: :signed_in, account: account, organization: organization)
    else
      Result.new(status: :denied, account: account)
    end
  end

  private

  attr_reader :auth

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
