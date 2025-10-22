class MenuItem < ApplicationRecord
  belongs_to :menu

  validates_presence_of :name, :price, :menu_id
end
