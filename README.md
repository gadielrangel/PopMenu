# PopMenu - Restaurant Menu Management System

A Rails API application for managing restaurants, menus, and menu items with JSON import capabilities.

## Requirements Covered

This project implements all requirements from the PopMenu interview project:

### Level 1: Basics
- Menu and MenuItem models with typical restaurant data
- Menu has many MenuItems (many-to-many relationship)
- RESTful endpoints for all models
- Comprehensive unit test coverage

### Level 2: Multiple Menus
- Restaurant model with multiple Menus
- MenuItems are not duplicated (uniqueness by name + price)
- MenuItems can appear on multiple Menus within a Restaurant
- RESTful endpoints for Restaurant data

### Level 3: JSON Import
- HTTP endpoint for JSON file import
- MenuImportService for data conversion and persistence
- Model validations with normalization
- Detailed logging for each item (success/skip with reasons)
- Success/fail result reporting
- Exception handling and error recovery
- Full unit test coverage

## Technology Stack

- **Ruby**: 3.5.0-preview1
- **Rails**: 8.0.3
- **Database**: SQLite3
- **Testing**: Minitest

## Getting Started

### Prerequisites

- Ruby 3.5.0 or higher
- Bundler
- SQLite3

### Installation

1. Clone the repository:
```bash
git clone https://github.com/gadielrangel/PopMenu
cd PopMenu
```

2. Install dependencies:
```bash
bundle install
```

3. Setup the database:
```bash
bin/rails db:create
bin/rails db:migrate
```

4. Run the test suite:
```bash
bin/rails test
```

All 41 tests should pass.

### Running the Application

Start the Rails server:
```bash
bin/rails server
```

The API will be available at `http://localhost:3000`

## Data Models

### Restaurant
- `name` (string, required, no whitespace-only)
- Has many Menus

### Menu
- `name` (string, required, no whitespace-only)
- Belongs to Restaurant
- Has many MenuItems (through menu_entries)

### MenuItem
- `name` (string, required, no whitespace-only)
- `price` (integer, required, must be > 0, stored in cents)
- Has many Menus (through menu_entries)
- Unique by name + price combination

### MenuEntry (Join Table)
- Links Menus to MenuItems (many-to-many)

## API Endpoints

### Restaurants

#### List all restaurants
```bash
GET /restaurants
```

#### Get a single restaurant
```bash
GET /restaurants/:id
```

#### Create a restaurant
```bash
POST /restaurants
Content-Type: application/json

{
  "restaurant": {
    "name": "My Restaurant"
  }
}
```

#### Update a restaurant
```bash
PATCH /restaurants/:id
Content-Type: application/json

{
  "restaurant": {
    "name": "Updated Name"
  }
}
```

#### Delete a restaurant
```bash
DELETE /restaurants/:id
```

### Menus

#### List all menus
```bash
GET /menus
```

#### Get a single menu
```bash
GET /menus/:id
```

#### Create a menu
```bash
POST /menus
Content-Type: application/json

{
  "menu": {
    "name": "Lunch Menu",
    "restaurant_id": 1
  }
}
```

#### Update a menu
```bash
PATCH /menus/:id
Content-Type: application/json

{
  "menu": {
    "name": "Updated Menu Name"
  }
}
```

#### Delete a menu
```bash
DELETE /menus/:id
```

### Menu Items

#### List all menu items
```bash
GET /menu_items
```

#### Get a single menu item
```bash
GET /menu_items/:id
```

#### Create a menu item
```bash
POST /menu_items
Content-Type: application/json

{
  "menu_item": {
    "name": "Burger",
    "price": 12
  }
}
```

#### Update a menu item
```bash
PATCH /menu_items/:id
Content-Type: application/json

{
  "menu_item": {
    "name": "Premium Burger",
    "price": 15
  }
}
```

#### Delete a menu item
```bash
DELETE /menu_items/:id
```

## JSON Import Feature

### Import Endpoint

The application provides a specialized endpoint for importing restaurant data from JSON files.

```bash
POST /restaurants/import
```

### JSON Format

The import endpoint accepts JSON with the following structure:

```json
{
  "restaurants": [
    {
      "name": "Restaurant Name",
      "menus": [
        {
          "name": "Menu Name",
          "menu_items": [
            {
              "name": "Item Name",
              "price": 10.00
            }
          ]
        }
      ]
    }
  ]
}
```

**Important Notes:**
- Prices can be decimals or integers
- The system uses `menu_items` (not `dishes` - menus with `dishes` key will be skipped)
- Whitespace in names is automatically trimmed
- Empty or whitespace-only names are rejected
- Prices must be greater than 0

### Using the Import Feature

#### Option 1: Import from JSON string (request body)

```bash
curl -X POST http://localhost:3000/restaurants/import \
  -H "Content-Type: application/json" \
  -d '{
    "restaurants": [
      {
        "name": "My Restaurant",
        "menus": [
          {
            "name": "Lunch",
            "menu_items": [
              {"name": "Burger", "price": 12},
              {"name": "Salad", "price": 8}
            ]
          }
        ]
      }
    ]
  }'
```

#### Option 2: Import from JSON file

```bash
curl -X POST http://localhost:3000/restaurants/import \
  -H "Content-Type: application/json" \
  -d @sample_restaurant_data.json
```

A sample data file is included at `sample_restaurant_data.json`.

### Import Response

**Success Response:**
```json
{
  "success": true,
  "error": null
}
```

**Error Response:**
```json
{
  "success": false,
  "error": "Error message describing what went wrong"
}
```

### Import Logging

The import process logs detailed information to Rails.logger (stdout in development):

```
[OK] Restaurant: Poppo's Cafe
[OK] Menu: lunch
[OK] MenuItem: Burger ($9)
[SKIP] Menu: dinner (dishes key not supported)
[SKIP] MenuItem: Name can't be blank
[SKIP] MenuItem: Price must be greater than 0
```

**Log Types:**
- `[OK]`: Successfully created or found existing record
- `[SKIP]`: Record skipped with reason (validation error, unsupported format, etc.)
- `[ERROR]`: Critical error that stops the import

### Import Behavior

**Idempotent:** Re-importing the same data won't create duplicates
- Restaurants are matched by name
- Menus are matched by name within a restaurant
- MenuItems are matched by name + price combination

**Validation:** The import enforces model validations
- Names cannot be empty or whitespace-only
- Prices must be positive integers
- Invalid records are skipped with logged error messages

**Transaction Safety:** All imports happen in a database transaction
- If a critical error occurs, all changes are rolled back
- Individual validation failures are logged but don't stop the import

**Partial Success:** Valid items are imported even if some items fail validation
- The response will still show `success: true`
- Check logs to see which items were skipped and why

## Architecture & Design Decisions

### Service Object Pattern

The `MenuImportService` handles JSON import logic:
- Parses and validates JSON structure
- Orchestrates the import process
- Handles errors gracefully
- Logs detailed information about each operation

**Location:** `app/services/menu_import_service.rb`

### Model Validations & Normalization

Models follow Rails conventions:
- **Normalization** happens in `before_validation` callbacks
  - Names: Strip whitespace
  - Prices: Convert to integers
- **Validation** ensures data integrity
  - Presence checks
  - Format validation (no whitespace-only names)
  - Uniqueness constraints
  - Numericality constraints

This separation ensures:
- Models own their data format
- Validation errors provide clear messages
- Any code creating records gets normalization automatically

### Many-to-Many Relationship

MenuItems and Menus use a many-to-many relationship through `menu_entries`:
- A MenuItem can appear on multiple Menus
- A Menu can have multiple MenuItems
- MenuItems are not duplicated (same name + price = same item)
- This allows efficient reuse of menu items across different menus

## Testing

The application has comprehensive test coverage:

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/restaurant_test.rb
bin/rails test test/services/menu_import_service_test.rb

# Run specific test
bin/rails test test/models/menu_item_test.rb:10
```

**Test Coverage:**
- Model validations and relationships
- Controller actions and error handling
- Service object behavior (import success/failure scenarios)
- Edge cases (empty data, invalid JSON, validation failures)

## Error Handling

The application handles various error scenarios:

1. **Invalid JSON:** Returns 422 with error message
2. **Missing required structure:** Returns 422 with clear error message
3. **File too large (>10MB):** Returns 422 with size limit error
4. **Validation failures:** Logged with specific validation messages
5. **Database errors:** Caught and logged with appropriate error responses

## Development Notes

### Database Schema

```ruby
# Restaurants
create_table "restaurants" do |t|
  t.string "name", null: false
  t.timestamps
end

# Menus
create_table "menus" do |t|
  t.string "name", null: false
  t.bigint "restaurant_id", null: false
  t.timestamps
end

# MenuItems
create_table "menu_items" do |t|
  t.string "name", null: false
  t.integer "price", null: false
  t.timestamps
end

# MenuEntries (join table)
create_table "menu_entries" do |t|
  t.bigint "menu_id", null: false
  t.bigint "menu_item_id", null: false
  t.timestamps
end
```

### Code Style

- Follows Rails conventions and idioms
- Uses Ruby 3+ syntax (e.g., endless methods, pattern matching)
- Service objects for complex business logic
- Struct for simple data objects
- Guard clauses for early returns
- Meaningful constant names

## License

This project is for interview purposes.
