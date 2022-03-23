# frozen_string_literal: true

DhpConnectedDevices::Engine.routes.draw do
  get '/hello', to: 'hellos#index'
end
