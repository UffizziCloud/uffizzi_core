# frozen_string_literal: true

class UffizziCore::Api::Cli::V1::Account::CredentialsController < UffizziCore::Api::Cli::V1::Account::ApplicationController
  def create
    credential_form = UffizziCore::Api::Cli::V1::Account::Credential::CreateForm.new
    credential_form.assign_attributes(credential_params)
    credential_form.account = resource_account
    credential_form.registry_url = Settings.docker_hub.registry_url if credential_form.docker_hub?
    if credential_form.google?
      credential_form.registry_url = Settings.google.registry_url
      credential_form.username = '_json_key'
    end
    credential_form.activate

    if credential_form.save
      UffizziCore::Account::CreateCredentialJob.perform_async(credential_form.id)
    end

    respond_with credential_form
  end

  private

  def credential_params
    params.require(:credential)
  end
end
