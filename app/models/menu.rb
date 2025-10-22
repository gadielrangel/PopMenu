class Menu < ApplicationRecord
  has_many :menu_items, class_name: "MenuItem", foreign_key: :menu_id, dependent: :destroy

  validates_presence_of :name
end
