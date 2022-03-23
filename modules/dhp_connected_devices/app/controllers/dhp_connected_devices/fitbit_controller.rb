module DhpConnectedDevices
  class FitbitController < ApplicationController
    def index
      render json: { greeting: "hello" }
    end
  end
end
