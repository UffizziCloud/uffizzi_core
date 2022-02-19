# frozen_string_literal: true

UffizziCore::Engine.routes.draw do
  namespace :api, defaults: { format: :json } do
    namespace :cli do
      namespace :v1 do
        resource :session, only: ['create', 'destroy']
      end
    end
  end
end
