# frozen_string_literal: true

Minerva::Engine.routes.draw do
  resources :resources, only: %i[index create update destroy]
  resources :subjects, only: [:index]
end
