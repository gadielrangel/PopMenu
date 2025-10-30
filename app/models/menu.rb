class Menu < ApplicationRecord
  has_many :menu_entries, dependent: :destroy
  has_many :menu_items, through: :menu_entries

  belongs_to :restaurant

  before_validation :normalize_name

  validates :name, presence: true
  validates :name, format: { with: /\A\S.*\S\z|\A\S\z/, message: "cannot be blank or only whitespace" }, if: -> { name.present? }

  private

  def normalize_name
    self.name = name.strip if name.is_a?(String)
  end
end
