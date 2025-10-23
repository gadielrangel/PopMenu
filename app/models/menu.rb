class Menu < ApplicationRecord
  has_many :menu_entries, dependent: :destroy
  has_many :menu_items, through: :menu_entries

  belongs_to :restaurant

  validates_presence_of :name, :restaurant
end
