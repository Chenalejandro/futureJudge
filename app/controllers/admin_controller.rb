class AdminController < ActionController::Base
  http_basic_authenticate_with name: ENV["ADMIN_USERNAME"].presence || "admin", password: ENV["ADMIN_PASSWORD"].presence || "1234"

end
