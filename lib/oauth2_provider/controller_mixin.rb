module Oauth2Provider
  module ControllerMixin
    def _oauth_provider_authenticate
      if api_request
        oauth_authorized   # uncomment to make all json API protected
      else
        session_auth
      end
    end

    def session_auth
      unless current_user
        render text: "Unauthorized access.", status: 401
        return false
      end
    end

    def api_request
      json?
    end

    def json?
      request.format == "application/json"
    end

    def _oauth_provider_json_body
      body = request.body.read.to_s
      @body = if body.empty?
        HashWithIndifferentAccess.new({})
      else
        HashWithIndifferentAccess.new(Rack::Utils.parse_nested_query body)
      end
    end

    def oauth_authorized
      action = params[:controller] + "/" + params[:action]
      _oauth_provider_normalize_token
      @token = Oauth2Provider::Token.to_adapter.find_first(token: params[:token], scope: action)
      if @token.nil? or @token.blocked?
        render text: "Unauthorized access.", status: 401
        return false
      else
        access = Oauth2Provider::Access.to_adapter.find_first(client_uri: @token.client_uri , resource_owner_uri: @token.resource_owner_uri)
        access.accessed!
        @current_user = User.to_adapter.find_first(id: @token.resource_owner_uri.split('/').last)
      end
    end

    def _oauth_provider_normalize_token
      # Token in the body
      if (_oauth_provider_json_body and @body[:token])
        params[:token] = @body[:token]
      end
      # Token in the header
      if request.env["Authorization"]
        params[:token] = request.env["Authorization"].split(" ").last
      end
    end
  end
end
