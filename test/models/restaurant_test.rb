require "test_helper"

class RestaurantTest < ActiveSupport::TestCase
  test "should not save without name" do
    menu_item = MenuItem.new
    assert_not menu_item.save
  end
end
