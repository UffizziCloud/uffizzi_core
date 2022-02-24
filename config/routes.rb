# frozen_string_literal: true

UffizziCore::Engine.routes.draw do
  namespace :api, defaults: { format: :json } do
    namespace :cli do
      namespace :v1 do
        resources :projects, only: ['index'], param: :slug do
          scope module: :projects do
            resources :secrets, only: ['index', 'destroy'] do
              collection do
                post :bulk_create
              end
            end
          end
        end
        resource :session, only: ['create', 'destroy']
      end
    end
  end
end
