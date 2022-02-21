# frozen_string_literal: true

UffizziCore::Engine.routes.draw do
  mount Rswag::Api::Engine => '/api-docs'
  mount Rswag::Ui::Engine => '/api-docs'
  namespace :api, defaults: { format: :json } do
    namespace :cli do
      namespace :v1 do
        resources :projects, only: ['index'], param: :slug do
          scope module: :projects do
            resource :compose_file, only: ['show', 'create', 'destroy']
          end
        end
        resource :session, only: ['create', 'destroy']
      end
    end
  end
end
