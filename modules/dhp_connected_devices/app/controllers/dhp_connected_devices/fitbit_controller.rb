# frozen_string_literal: true

require 'fitbit/client'

module DhpConnectedDevices
  class FitbitController < ApplicationController
    skip_before_action :authenticate

    def connect
      auth_url = fitbit_api.auth_url
      redirect_to auth_url
    end

    def callback
      auth_code = callback_params[:code]
      res = fitbit_api.get_token(auth_code)
      render json: { code: callback_params[:code], token: res.body }
    end

    private

    def fitbit_api
      @fitbit_client ||= DhpConnectedDevices::Fitbit::Client.new
    end

    def callback_params
      params.permit(:code)
    end
  end
end
