class CreateMenuEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :menu_entries do |t|
      t.references :menu, null: false, foreign_key: true
      t.references :menu_item, null: false, foreign_key: true

      t.timestamps
    end
  end
end
