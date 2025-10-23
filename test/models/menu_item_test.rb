require "test_helper"

class MenuItemTest < ActiveSupport::TestCase
  test "should not save without name" do
    menu_item = MenuItem.new
    assert_not menu_item.save
  end

  test "should not save without price" do
    menu_item = MenuItem.new(name: "Test Item")
    assert_not menu_item.save
  end

  test "should validate presence of name" do
    menu_item = MenuItem.new(price: 10)
    assert_not menu_item.valid?
    assert menu_item.errors[:name].any?
  end

  test "should validate presence of price" do
    menu_item = MenuItem.new(name: "Test Item")
    assert_not menu_item.valid?
    assert menu_item.errors[:price].any?
  end

  test "should allow same name with different price" do
    MenuItem.create!(name: "Burger", price: 900)
    menu_item = MenuItem.new(name: "Burger", price: 1500)
    assert menu_item.valid?
    assert menu_item.save
  end

  test "should not allow duplicate name and price combination" do
    MenuItem.create!(name: "Burger", price: 900)
    menu_item = MenuItem.new(name: "Burger", price: 900)
    assert_not menu_item.valid?
    assert menu_item.errors[:name].any?
  end
end
