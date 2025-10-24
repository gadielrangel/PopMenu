class MenusController < ApplicationController
  before_action :set_menu, only: %i[ show update destroy ]

  # GET /menus
  def index
    @menus = Menu.includes(:menu_items).all

    render json: @menus, include: :menu_items
  end

  # GET /menus/1
  def show
    render json: @menu
  end

  # POST /menus
  def create
    @menu = Menu.new(menu_params)

    if @menu.save
      render json: @menu, status: :created, location: @menu
    else
      render json: @menu.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /menus/1
  def update
    if @menu.update(menu_params)
      render json: @menu
    else
      render json: @menu.errors, status: :unprocessable_content
    end
  end

  # DELETE /menus/1
  def destroy
    @menu.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_menu
      @menu = Menu.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def menu_params
      params.expect(menu: [ :name, :restaurant_id ])
    end
end
