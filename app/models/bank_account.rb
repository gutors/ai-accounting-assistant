class BankAccount < ApplicationRecord
  belongs_to :organization
  belongs_to :bank

  has_many :bank_statements, dependent: :restrict_with_exception

  before_validation :assign_slug
  before_validation :normalize_coordinates

  validates :name, presence: true, uniqueness: { scope: :organization_id }
  validates :slug, presence: true, uniqueness: { scope: :organization_id }

  def self.create_for(organization:, name:, compe:, coordinates: nil)
    record = new(
      organization: organization,
      bank: Bank.find_by(compe: compe),
      name: name.to_s.strip.presence,
      coordinates: coordinates
    )
    record.save
    record
  rescue ActiveRecord::RecordNotUnique
    record.errors.add(:name, :taken)
    record
  end

  def apply_from(params)
    self.name = params[:name].to_s.strip.presence if params.key?(:name)
    self.coordinates = params[:coordinates] if params.key?(:coordinates)
    if params.key?(:compe)
      self.bank = Bank.find_by(compe: params[:compe])
    end
    if params.key?(:active)
      self.active = ActiveModel::Type::Boolean.new.cast(params[:active])
    end
    save
  rescue ActiveRecord::RecordNotUnique
    errors.add(:name, :taken)
    false
  end

  private

  def assign_slug
    self.slug = ActiveSupport::Inflector.parameterize(name.to_s).presence
  end

  def normalize_coordinates
    self.coordinates = coordinates.to_s.strip.presence
  end
end
