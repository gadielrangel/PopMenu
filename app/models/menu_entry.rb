class MenuEntry < ApplicationRecord
  belongs_to :menu
  belongs_to :menu_item
end
