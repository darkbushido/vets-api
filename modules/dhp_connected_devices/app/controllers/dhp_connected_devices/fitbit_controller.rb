module DhpConnectedDevices
  class FitbitController < ApplicationController
    # skip_before_action :authenticate

    def initialize
      super
      # TODO move to config/initializers
      @client = FitbitAPI::Client.new(client_id: '<client_id>',
                                      client_secret: '<client_secret>',
                                      redirect_uri: 'http://localhost:3000/dhp_connected_devices/fitbit-callback',
                                      scope: 'heartrate activity nutrition sleep')

      # @code_verifier = SecureRandom.alphanumeric(100)
      # @code_challenge = generate_pkce_challenge(@code_verifier)
    end

    def index
      render json: { greeting: "hello" }
    end

    def connect
      auth_url = @client.auth_url # + "&code_challenge=#{@code_challenge}&code_challenge_method=S256"
      redirect_to auth_url
    end

    def callback
      auth_code = callback_params[:code]
      token = @client.get_token(auth_code)

      render json: { code: callback_params[:code], token: token }
    end

    private

    def callback_params
      params.permit(:code)
    end
    #
    # def generate_pkce_challenge(code_verifier)
    #   urlsafe_base64(Digest::SHA256.base64digest(code_verifier))
    # end
    #
    # def urlsafe_base64(base64_str)
    #   base64_str.tr("+/", "-_").tr("=", "")
    # end
  end
end
