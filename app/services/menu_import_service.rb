class MenuImportService
  Result = Struct.new(:success, :error, keyword_init: true) do
    def success? = success
  end

  INVALID_DATA = "invalid data"
  DISHES_NOT_SUPPORTED = "dishes key not supported"
  INVALID_STRUCTURE = "Invalid JSON structure: expected 'restaurants' array"

  def self.call(json_data)
    new(json_data).call
  end

  def initialize(json_data)
    @json_data = json_data
  end

  def call
    parse_json
      .then { |data| validate_structure(data) }
      .then { |data| import_all(data["restaurants"]) }
      .then { Result.new(success: true) }
  rescue JSON::ParserError => e
    Result.new(success: false, error: "JSON parsing error: #{e.message}")
  rescue StandardError => e
    Rails.logger.error "[ERROR] #{e.message}"
    Result.new(success: false, error: "Import error: #{e.message}")
  end

  private

  def parse_json
    parsed = case @json_data
    when String then JSON.parse(@json_data)
    when Hash then @json_data
    else @json_data.respond_to?(:read) ? JSON.parse(@json_data.read) : nil
    end

    raise JSON::ParserError, "Empty or invalid input" if parsed.blank? || !parsed.is_a?(Hash)
    parsed
  end

  def validate_structure(data)
    data.fetch("restaurants").is_a?(Array) ? data : raise(ArgumentError, INVALID_STRUCTURE)
  rescue KeyError
    raise ArgumentError, INVALID_STRUCTURE
  end

  def import_all(restaurants)
    ActiveRecord::Base.transaction do
      restaurants.each { |r| import_restaurant(r) }
    end
  end

  def import_restaurant(data)
    return log_skip("Restaurant", INVALID_DATA) unless data.is_a?(Hash)

    attrs = { name: data["name"] }
    restaurant = find_or_create(Restaurant, attrs)
    return unless restaurant

    log_ok("Restaurant", restaurant.name)
    Array(data["menus"]).each { |menu_data| import_menu(restaurant, menu_data) }
  end

  def import_menu(restaurant, data)
    return log_skip("Menu", INVALID_DATA) unless data.is_a?(Hash)
    return log_skip("Menu", DISHES_NOT_SUPPORTED) if data.key?("dishes")

    attrs = { name: data["name"] }
    menu = find_or_create(restaurant.menus, attrs)
    return unless menu

    log_ok("Menu", menu.name)
    Array(data["menu_items"]).each { |item_data| import_menu_item(menu, item_data) }
  end

  def import_menu_item(menu, data)
    return log_skip("MenuItem", INVALID_DATA) unless data.is_a?(Hash)

    attrs = {
      name: data["name"],
      price: data["price"]
    }
    item = find_or_create(MenuItem, attrs)
    return unless item

    log_ok("MenuItem", "#{item.name} ($#{item.price})")
    link_to_menu(menu, item)
  end

  def link_to_menu(menu, item)
    menu.menu_items << item unless menu.menu_entries.exists?(menu_item_id: item.id)
  end

  def find_or_create(scope, attrs)
    scope.find_or_create_by!(attrs)
  rescue ActiveRecord::RecordInvalid => e
    log_skip(scope.model_name.human, e.record.errors.full_messages.join(", "))
    nil
  end

  def log_skip(model, reason)
    Rails.logger.info "[SKIP] #{model}: #{reason}"
  end

  def log_ok(model, details)
    Rails.logger.info "[OK] #{model}: #{details}"
  end
end
