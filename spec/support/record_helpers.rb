module RecordHelpers
  def plant_coordinator(email: "coord@example.com", organization_name: "ONG Norte", google_uid: "uid-#{email}")
    organization = Organization.create!(name: organization_name)
    account = Account.create!(email: email, google_uid: google_uid)
    Access.create!(account: account, organization: organization, kind: :coordinator)
    [ account, organization ]
  end

  def plant_submitter(email: "submitter@example.com", organization: nil, organization_name: "ONG Norte", google_uid: "uid-#{email}")
    organization ||= Organization.create!(name: organization_name)
    account = Account.create!(email: email, google_uid: google_uid)
    Access.create!(account: account, organization: organization, kind: :submitter)
    [ account, organization ]
  end

  def truncate_product_tables
    ActiveStorage::VariantRecord.delete_all
    ActiveStorage::Attachment.delete_all
    ActiveStorage::Blob.delete_all
    Payment.delete_all
    Inflow.delete_all
    BankStatement.delete_all
    SupportingDocument.delete_all
    Justification.delete_all
    Match.delete_all
    Month.delete_all
    BankAccount.delete_all
    Invite.delete_all
    Access.delete_all
    Account.delete_all
    Organization.delete_all
  end
end
