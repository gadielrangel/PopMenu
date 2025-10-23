class AddUniqueIndexToMenuItems < ActiveRecord::Migration[8.0]
  def change
    add_index :menu_items, [:name, :price], unique: true
  end
end
