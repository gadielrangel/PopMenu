require "test_helper"

class MenuTest < ActiveSupport::TestCase
  test "should not save without name" do
    menu = Menu.new
    assert_not menu.save
  end

  test "should validate presence of name" do
    menu_item = Menu.new
    assert_not menu_item.valid?
    assert menu_item.errors[:name].any?
  end
end
