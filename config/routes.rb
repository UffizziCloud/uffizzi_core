# frozen_string_literal: true

UffizziCore::Engine.routes.draw do
  namespace :api, defaults: { format: :json } do
    namespace :cli do
      namespace :v1 do
        resources :projects, only: ['index']
        resource :session, only: ['create', 'destroy']
      end
    end
  end
end
