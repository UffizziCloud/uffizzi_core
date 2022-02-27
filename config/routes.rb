# frozen_string_literal: true

UffizziCore::Engine.routes.draw do
  namespace :api, defaults: { format: :json } do
    namespace :cli do
      namespace :v1 do
        resources :projects, only: %w(index), param: :slug do
          scope module: :projects do
            resources :deployments, only: %w(index show create destroy) do
              post :deploy_containers, on: :member
              scope module: :deployments do
                resources :activity_items, only: %w(index)
              end
            end
          end
        end
        resource :session, only: ['create', 'destroy']
      end
    end
  end
end
