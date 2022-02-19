# frozen_string_literal: true

require 'test_helper'
# require "database/setup"

class UffizziCore::Api::Cli::V1::SessionsControllerTest < ActionController::TestCase
  setup do
    @routes = UffizziCore::Engine.routes
  end

  test '#create - successful' do
    password = generate(:password)
    user = create(:user, :active, password: password)
    params = { email: user.email, password: password }

    post :create, params: { user: params }, format: :json

    assert_response :success
    assert { signed_in? }
  end

  test '#create - failed with wrong password' do
    password = generate(:password)
    user = create(:user, :active, password: password)
    wrong_password = generate(:password)
    params = { email: user.email, password: wrong_password }

    post :create, params: { user: params }, format: :json

    assert_response :unprocessable_entity
    assert_not_empty JSON.parse(response.body)['errors']
    assert { !signed_in? }
  end
end
