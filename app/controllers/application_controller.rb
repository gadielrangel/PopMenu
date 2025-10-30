class ApplicationController < ActionController::API
  # Handle JSON parsing errors that occur before controller actions run
  # This catches errors from Rails parameter parsing middleware
  rescue_from ActionDispatch::Http::Parameters::ParseError do |exception|
    render json: { success: false, error: "Invalid JSON format" },
           status: :unprocessable_content
  end
end
