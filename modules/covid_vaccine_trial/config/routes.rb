CovidVaccineTrial::Engine.routes.draw do
  namespace :screener, defaults: { format: :json } do
    put 'create', to: 'submissions#create'
  end
end
