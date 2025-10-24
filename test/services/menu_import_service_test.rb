require "test_helper"

class MenuImportServiceTest < ActiveSupport::TestCase
  test "successfully imports valid restaurant data" do
    json_data = {
      "restaurants" => [
        {
          "name" => "Test Restaurant",
          "menus" => [
            {
              "name" => "lunch",
              "menu_items" => [
                { "name" => "Burger", "price" => 9.00 },
                { "name" => "Fries", "price" => 3.50 }
              ]
            }
          ]
        }
      ]
    }.to_json

    result = MenuImportService.call(json_data)

    assert result[:success]

    restaurant = Restaurant.find_by(name: "Test Restaurant")
    assert_not_nil restaurant
    assert_equal 1, restaurant.menus.count

    menu = restaurant.menus.first
    assert_equal "lunch", menu.name
    assert_equal 2, menu.menu_items.count
  end

  test "skips menus with dishes key" do
    json_data = {
      "restaurants" => [
        {
          "name" => "Test Restaurant",
          "menus" => [
            {
              "name" => "dinner",
              "dishes" => [
                { "name" => "Steak", "price" => 25.00 }
              ]
            },
            {
              "name" => "lunch",
              "menu_items" => [
                { "name" => "Burger", "price" => 9.00 }
              ]
            }
          ]
        }
      ]
    }.to_json

    result = MenuImportService.call(json_data)

    assert result[:success]

    restaurant = Restaurant.find_by(name: "Test Restaurant")
    assert_equal 1, restaurant.menus.count
    assert_equal "lunch", restaurant.menus.first.name
  end

  test "handles duplicate menu items across menus" do
    json_data = {
      "restaurants" => [
        {
          "name" => "Test Restaurant Duplicate Items",
          "menus" => [
            {
              "name" => "lunch",
              "menu_items" => [
                { "name" => "Duplicate Test Burger", "price" => 9 }
              ]
            },
            {
              "name" => "dinner",
              "menu_items" => [
                { "name" => "Duplicate Test Burger", "price" => 9 }
              ]
            }
          ]
        }
      ]
    }.to_json

    result = MenuImportService.call(json_data)

    assert result[:success]

    # Should only create one MenuItem
    assert_equal 1, MenuItem.where(name: "Duplicate Test Burger", price: 9).count

    # But it should be in both menus
    restaurant = Restaurant.find_by(name: "Test Restaurant Duplicate Items")
    assert_equal 2, restaurant.menus.count
    restaurant.menus.each do |menu|
      assert_equal 1, menu.menu_items.count
      assert_equal "Duplicate Test Burger", menu.menu_items.first.name
    end
  end

  test "allows same name with different prices" do
    json_data = {
      "restaurants" => [
        {
          "name" => "Test Restaurant Different Prices",
          "menus" => [
            {
              "name" => "lunch",
              "menu_items" => [
                { "name" => "Different Price Burger", "price" => 9 },
                { "name" => "Different Price Burger", "price" => 15 }
              ]
            }
          ]
        }
      ]
    }.to_json

    result = MenuImportService.call(json_data)

    assert result[:success]

    # Should create two MenuItems
    assert_equal 1, MenuItem.where(name: "Different Price Burger", price: 9).count
    assert_equal 1, MenuItem.where(name: "Different Price Burger", price: 15).count
  end

  test "is idempotent - reimporting same data doesnt duplicate" do
    json_data = {
      "restaurants" => [
        {
          "name" => "Idempotent Test Restaurant",
          "menus" => [
            {
              "name" => "lunch",
              "menu_items" => [
                { "name" => "Idempotent Burger", "price" => 9 }
              ]
            }
          ]
        }
      ]
    }.to_json

    # First import
    result1 = MenuImportService.call(json_data)
    assert result1[:success]

    restaurant_count_after_first = Restaurant.count
    menu_count_after_first = Menu.count
    menu_item_count_after_first = MenuItem.count

    # Second import
    result2 = MenuImportService.call(json_data)
    assert result2[:success]

    # Should not create duplicates
    assert_equal restaurant_count_after_first, Restaurant.count
    assert_equal menu_count_after_first, Menu.count
    assert_equal menu_item_count_after_first, MenuItem.count
  end

  test "handles missing restaurant name" do
    json_data = {
      "restaurants" => [
        {
          "menus" => [
            {
              "name" => "lunch",
              "menu_items" => [
                { "name" => "Burger", "price" => 9 }
              ]
            }
          ]
        }
      ]
    }.to_json

    initial_count = Restaurant.count

    result = MenuImportService.call(json_data)

    assert result[:success]
    assert_equal initial_count, Restaurant.count
  end

  test "handles missing menu name" do
    json_data = {
      "restaurants" => [
        {
          "name" => "Test Restaurant Missing Menu Name",
          "menus" => [
            {
              "menu_items" => [
                { "name" => "Burger", "price" => 9 }
              ]
            }
          ]
        }
      ]
    }.to_json

    initial_menu_count = Menu.count

    result = MenuImportService.call(json_data)

    assert result[:success]
    assert_equal initial_menu_count, Menu.count
  end

  test "handles missing menu item name or price" do
    json_data = {
      "restaurants" => [
        {
          "name" => "Test Restaurant Missing Item Fields",
          "menus" => [
            {
              "name" => "lunch",
              "menu_items" => [
                { "name" => "Burger" },
                { "price" => 9 }
              ]
            }
          ]
        }
      ]
    }.to_json

    initial_menu_item_count = MenuItem.count

    result = MenuImportService.call(json_data)

    assert result[:success]
    assert_equal initial_menu_item_count, MenuItem.count
  end

  test "handles invalid JSON" do
    json_data = "{ invalid json }"

    result = MenuImportService.call(json_data)

    assert_not result[:success]
    assert_includes result[:error], "JSON parsing error"
  end

  test "handles empty restaurants array" do
    json_data = {
      "restaurants" => []
    }.to_json

    initial_count = Restaurant.count

    result = MenuImportService.call(json_data)

    assert result[:success]
    assert_equal initial_count, Restaurant.count
  end

  test "handles missing restaurants key" do
    json_data = {
      "data" => []
    }.to_json

    result = MenuImportService.call(json_data)

    assert_not result[:success]
    assert_includes result[:error], "Invalid JSON structure"
  end

  test "stores prices as integers" do
    json_data = {
      "restaurants" => [
        {
          "name" => "Test Restaurant Price Format",
          "menus" => [
            {
              "name" => "lunch",
              "menu_items" => [
                { "name" => "Price Test Burger", "price" => 10 }
              ]
            }
          ]
        }
      ]
    }.to_json

    result = MenuImportService.call(json_data)

    assert result[:success]

    menu_item = MenuItem.find_by(name: "Price Test Burger")
    assert_equal 10, menu_item.price
  end
end
