class RestaurantsController < ApplicationController
  before_action :set_restaurant, only: %i[ show update destroy ]

  # GET /restaurants
  def index
    @restaurants = Restaurant.all

    render json: @restaurants
  end

  # GET /restaurants/1
  def show
    render json: @restaurant
  end

  # POST /restaurants
  def create
    @restaurant = Restaurant.new(restaurant_params)

    if @restaurant.save
      render json: @restaurant, status: :created, location: @restaurant
    else
      render json: @restaurant.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /restaurants/1
  def update
    if @restaurant.update(restaurant_params)
      render json: @restaurant
    else
      render json: @restaurant.errors, status: :unprocessable_content
    end
  end

  # DELETE /restaurants/1
  def destroy
    @restaurant.destroy!
  end

  # POST /restaurants/import
  def import
    # Check file size limit before reading
    max_size = 10.megabytes
    content_length = request.headers['Content-Length'].to_i

    if content_length > max_size
      return render json: {
        success: false,
        error: "File too large. Maximum size is #{max_size / 1.megabyte}MB"
      }, status: :unprocessable_content
    end

    json_data = if params[:file].present?
      params[:file]
    else
      body_content = request.body.read
      if body_content.blank?
        return render json: { success: false, error: "No file or JSON data provided" },
                      status: :unprocessable_content
      end
      body_content
    end

    result = MenuImportService.call(json_data)

    # Service returns a result hash with success flag
    # The service handles all errors internally and returns appropriate error messages
    if result[:success]
      render json: result, status: :ok
    else
      render json: result, status: :unprocessable_content
    end
  rescue => e
    # Catch any errors (including those the service doesn't handle)
    Rails.logger.error "[RestaurantsImport] Error: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    render json: { success: false, error: e.message }, status: :unprocessable_content
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_restaurant
      @restaurant = Restaurant.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def restaurant_params
      params.expect(restaurant: [ :name ])
    end
end
