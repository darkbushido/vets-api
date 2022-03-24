module DhpConnectedDevices
  class FitbitController < ApplicationController
    skip_before_action :authenticate

    def initialize
      super
      # TODO move to config/initializers
      @client_id = '<client_id>'
      @client_secret = '<client_secret>'
      @client = FitbitAPI::Client.new(client_id: @client_id,
                                      client_secret: @client_secret,
                                      redirect_uri: 'http://localhost:3000/dhp_connected_devices/fitbit-callback',
                                      scope: 'heartrate activity nutrition sleep')
      # TODO use pkce generator library
      # @pkce_challenge = PkceChallenge.challenge(char_length: 128)
      @code_verifier = SecureRandom.alphanumeric(128)
      @code_challenge = generate_pkce_challenge(@code_verifier)
      @connection = connection
    end

    def index
      render json: { greeting: "hello" }
    end

    def connect
      auth_url = @client.auth_url + "&code_challenge=#{@code_challenge}&code_challenge_method=S256"
      redirect_to auth_url
    end

    def callback
      auth_code = callback_params[:code]
      # token = @client.get_token(auth_code)
      res = post('https://api.fitbit.com/oauth2/token',
                 "client_id=#{@client_id}&code=#{auth_code}&code_verifier=#{@code_verifier}&grant_type=authorization_code&redirect_uri=http://localhost:3000/dhp_connected_devices/fitbit-callback")
      p(res)
      render json: { code: callback_params[:code], token: res.body }
    end

    private

    def post(path, params)
      @connection.post(path) { |req| req.body = params }
    end

    def connection
      Faraday.new(url: url, headers: headers) do |conn|
        # conn.response :health_quest_errors
        # conn.use :health_quest_logging
        conn.adapter Faraday.default_adapter
      end
    end

    def url
      'https://api.fitbit.com/oauth2/token'
    end

    def headers
      {
        'Authorization' => "Basic #{basicAuth}",
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    end

    def basicAuth
      Base64.urlsafe_encode64("#{@client_id}:#{@client_secret}")
    end

    def callback_params
      params.permit(:code)
    end

    def generate_pkce_challenge(code_verifier)
      urlsafe_base64(Digest::SHA256.base64digest(code_verifier))
    end

    def urlsafe_base64(base64_str)
      base64_str.tr("+/", "-_").tr("=", "")
    end
  end
end
