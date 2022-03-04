# frozen_string_literal: true

class UffizziCore::Api::Cli::V1::ComposeFile::CheckCredentialsForm
  include UffizziCore::ApplicationFormWithoutActiveRecord

  attribute :compose_file
  attribute :credentials

  validate :check_containers_credentials

  private

  def check_containers_credentials
    compose_content = Base64.decode64(compose_file.content)
    compose_data = { html_url: compose_file.source }
    compose_data = UffizziCore::Cli::ComposeFileService.parse(compose_content)

    UffizziCore::Cli::ComposeFileService.containers_credentials(compose_data, credentials)
  rescue UffizziCore::ComposeFile::CredentialsError => e
    errors.add(e.error_key, e.message)
  end
end
