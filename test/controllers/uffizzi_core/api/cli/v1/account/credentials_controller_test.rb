# frozen_string_literal: true

require 'test_helper'

class UffizziCore::Api::Cli::V1::Account::CredentialsControllerTest < ActionController::TestCase
  setup do
    @user = create(:user, :with_organizational_account)
    @account = @user.organizational_account
    @project = create(:project, :with_members, account: @account, members: [@user])

    sign_in @user

    Sidekiq::Worker.clear_all
    Sidekiq::Testing.fake!
  end

  teardown do
    Sidekiq::Worker.clear_all
    Sidekiq::Testing.inline!
  end

  test '#create docker hub credential' do
    api_tokens_response = UffizziCore::Converters.deep_lower_camelize_keys(
      {
        token: 'aed3ba75-41e2-4e5a-88f6-74406c88db1e',
      },
    )

    stub_dockerhub_api_tokens(api_tokens_response)
    stub_dockerhub_login
    stub_controller

    attributes = attributes_for(:credential, :docker_hub)
    params = { account_id: @account.id, credential: attributes }

    differences = {
      -> { UffizziCore::Credential.count } => 1,
    }

    assert_difference differences do
      post :create, params: params, format: :json
    end

    assert_response :success
  end

  test '#create azure credential' do
    registry_url = generate(:url)
    oauth2_token_response = { access_token: generate(:string) }

    stubbed_azure_registry_oauth2_token = stub_azure_registry_oauth2_token(registry_url, oauth2_token_response)

    attributes = attributes_for(:credential, :azure, registry_url: registry_url)
    params = { account_id: @account.id, credential: attributes }

    differences = {
      -> { UffizziCore::Credential.count } => 1,
    }

    assert_difference differences do
      post :create, params: params, format: :json
    end
    assert_requested stubbed_azure_registry_oauth2_token
    assert_response :success
  end

  test '#create google credential' do
    attributes = attributes_for(:credential, :google)
    params = { account_id: @account.id, credential: attributes }
    token_response = { token: generate(:string) }

    stubbed_google_registry_token = stub_google_registry_token(token_response)

    differences = {
      -> { UffizziCore::Credential.count } => 1,
    }

    assert_difference differences do
      post :create, params: params, format: :json
    end
    assert_requested stubbed_google_registry_token
    assert_response :success
  end

  test '#create amazon credential' do
    attributes = attributes_for(:credential, :amazon)
    params = { account_id: @account.id, credential: attributes }

    UffizziCore::Amazon::CredentialService.expects(:credential_correct?).at_least(1).returns(true)

    differences = {
      -> { UffizziCore::Credential.count } => 1,
    }

    assert_difference differences do
      post :create, params: params, format: :json
    end

    assert_response :success
  end

  test '#create duplicate credential' do
    stub_dockerhub_login
    stub_controller

    credential = create(:credential, :docker_hub, account: @account)

    differences = { -> { UffizziCore::Credential.count } => 0 }
    attributes = attributes_for(:credential, :docker_hub, account: @account)
    params = { account_id: @account.id, credential: attributes }

    assert_difference differences do
      post :create, params: params, format: :json
    end
    assert_response :unprocessable_entity
    assert_equal UffizziCore::Credential.last.id, credential.id
  end
end
