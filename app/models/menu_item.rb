class MenuItem < ApplicationRecord
  has_many :menu_entries, dependent: :destroy
  has_many :menus, through: :menu_entries

  before_validation :normalize_attributes

  validates :name, presence: true
  validates :name, format: { with: /\A\S.*\S\z|\A\S\z/, message: "cannot be blank or only whitespace" }, if: -> { name.present? }
  validates :name, uniqueness: { scope: :price }

  # no free items...
  validates :price, presence: true, numericality: { only_integer: true, greater_than: 0 }

  private

  def normalize_attributes
    self.name = name.strip if name.is_a?(String)
    self.price = price.to_i if price.present?
  end
end
