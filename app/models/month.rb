class Month < ApplicationRecord
  YEAR_MONTH = /\A\d{4}-(0[1-9]|1[0-2])\z/

  belongs_to :organization

  has_many :bank_statements, dependent: :restrict_with_exception

  validates :year_month, format: { with: YEAR_MONTH }
  validates :year_month, uniqueness: { scope: :organization_id }

  def self.open(organization:, year_month:)
    year_month = year_month.to_s.strip
    existing = organization.months.find_by(year_month: year_month)
    return existing if existing

    record = organization.months.new(year_month: year_month)
    record.save
    record
  rescue ActiveRecord::RecordNotUnique
    organization.months.find_by!(year_month: year_month)
  end

  def self.valid_year_month?(value)
    value.to_s.match?(YEAR_MONTH)
  end
end
