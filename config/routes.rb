# frozen_string_literal: true

Minerva::Engine.routes.draw do
  resources :resources, only: %i[index create update destroy]
  resources :subjects, only: [:index]
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  if ENV.fetch('ENABLE_SWAGGER', true).to_bool
    mount SwaggerUiEngine::Engine, at: "/swagger"
    get '/docs/swagger.yaml', to: 'swagger#index'
  end
end
