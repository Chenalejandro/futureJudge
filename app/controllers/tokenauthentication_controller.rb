class TokenauthenticationController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :authenticate

  private
    def authenticate
      authenticate_or_request_with_http_token do |token, options|
        # Compare the tokens in a time-constant manner, to mitigate
        # timing attacks.
        ActiveSupport::SecurityUtils.secure_compare(token, ENV["SOLIDCODE_AUTH_TOKEN"])
      end
    end
end
