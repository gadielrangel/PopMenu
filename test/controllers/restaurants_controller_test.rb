require "test_helper"

class RestaurantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restaurant = restaurants(:one)
  end

  test "should get index" do
    get restaurants_url, as: :json
    assert_response :success
  end

  test "should create restaurant" do
    assert_difference("Restaurant.count") do
      post restaurants_url, params: { restaurant: { name: @restaurant.name } }, as: :json
    end

    assert_response :created
  end

  test "should show restaurant" do
    get restaurant_url(@restaurant), as: :json
    assert_response :success
  end

  test "should update restaurant" do
    patch restaurant_url(@restaurant), params: { restaurant: { name: @restaurant.name } }, as: :json
    assert_response :success
  end

  test "should destroy restaurant" do
    assert_difference("Restaurant.count", -1) do
      delete restaurant_url(@restaurant), as: :json
    end

    assert_response :no_content
  end

  test "should import restaurant data from JSON body" do
    json_data = {
      "restaurants" => [
        {
          "name" => "Imported Restaurant",
          "menus" => [
            {
              "name" => "lunch",
              "menu_items" => [
                { "name" => "Test Burger", "price" => 10.00 }
              ]
            }
          ]
        }
      ]
    }

    assert_difference("Restaurant.count", 1) do
      assert_difference("Menu.count", 1) do
        assert_difference("MenuItem.count", 1) do
          post import_restaurants_url, params: json_data.to_json, headers: { "CONTENT_TYPE" => "application/json" }
        end
      end
    end

    assert_response :success

    response_data = JSON.parse(@response.body)
    assert response_data["success"]
  end

  test "should return error when no data provided" do
    post import_restaurants_url, headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :unprocessable_entity

    response_data = JSON.parse(@response.body)
    assert_not response_data["success"]
    assert_includes response_data["error"], "No file or JSON data provided"
  end

  test "should return error for invalid JSON" do
    post import_restaurants_url, params: "{ invalid json }", headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :unprocessable_entity

    response_data = JSON.parse(@response.body)
    assert_not response_data["success"]
  end
end
