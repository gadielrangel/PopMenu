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
end
