class MenuItem < ApplicationRecord
  has_many :menu_entries, dependent: :destroy
  has_many :menus, through: :menu_entries

  validates_presence_of :name, :price

  validates_uniqueness_of :name
end
