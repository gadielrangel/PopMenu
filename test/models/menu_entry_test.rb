require "test_helper"

class MenuEntryTest < ActiveSupport::TestCase
  test "should fail when menu is not present" do
    menu_entry = MenuEntry.new
    assert_not menu_entry.valid?
    assert menu_entry.errors[:menu].any?
  end

  test "should fail when menu_item_id is not present" do
    menu_entry = MenuEntry.new(menu_id: 1)
    assert_not menu_entry.valid?
    assert menu_entry.errors[:menu_item].any?
  end
end
