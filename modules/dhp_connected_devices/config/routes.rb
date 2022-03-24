# frozen_string_literal: true

DhpConnectedDevices::Engine.routes.draw do
  get '/hello', to: 'fitbit#index'
  get '/fitbit', to: 'fitbit#connect'
  get '/fitbit-callback', to: 'fitbit#callback'
end
