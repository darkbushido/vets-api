require_dependency "dhp_connected_devices/application_controller"

module DhpConnectedDevices
  class HellosController < ApplicationController
    def index
      render json: { greeting: "hello" }
    end
  end
end
