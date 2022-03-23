# frozen_string_literal: true

module DhpConnectedDevices
  class ApplicationController < ::ApplicationController
    skip_before_action :authenticate

  end
end
