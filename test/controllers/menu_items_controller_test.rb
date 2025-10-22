require "test_helper"

class MenuItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @menu_item = menu_items(:one)
  end

  test "should get index" do
    get menu_items_url, as: :json
    assert_response :success
  end

  test "should create menu_item" do
    assert_difference("MenuItem.count") do
      post menu_items_url, params: { menu_item: { menu_id: @menu_item.menu_id, name: @menu_item.name, price: @menu_item.price } }, as: :json
    end

    assert_response :created
  end

  test "should show menu_item" do
    get menu_item_url(@menu_item), as: :json
    assert_response :success
  end

  test "should update menu_item" do
    patch menu_item_url(@menu_item), params: { menu_item: { menu_id: @menu_item.menu_id, name: @menu_item.name, price: @menu_item.price } }, as: :json
    assert_response :success
  end

  test "should destroy menu_item" do
    assert_difference("MenuItem.count", -1) do
      delete menu_item_url(@menu_item), as: :json
    end

    assert_response :no_content
  end
end
