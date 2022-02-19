# frozen_string_literal: true

class UffizziCore::Credential < UffizziCore::ApplicationRecord
  include AASM
  include UffizziCore::CredentialRepo

  self.table_name = Rails.application.config.uffizzi_core[:table_names][:credentials]

  belongs_to :account

  before_destroy :remove_token

  validates :registry_url, presence: true

  aasm :state, column: :state do
    state :not_connected, initial: true
    state :active
    state :unauthorized

    event :activate do
      transitions from: [:not_connected, :unauthorized], to: :active
    end

    event :unauthorize do
      transitions from: [:not_connected, :active], to: :unauthorized
    end
  end

  def github?
    type == UffizziCore::Credential::Github.name
  end

  def docker_hub?
    type == UffizziCore::Credential::DockerHub.name
  end

  def azure?
    type == UffizziCore::Credential::Azure.name
  end

  def google?
    type == UffizziCore::Credential::Google.name
  end

  def amazon?
    type == UffizziCore::Credential::Amazon.name
  end

  private

  def remove_token
    account.projects.find_each do |project|
      project.deployments.find_each do |deployment|
        containers = deployment.containers
        attributes = { continuously_deploy: UffizziCore::Container::STATE_DISABLED }

        containers.with_github_repo.update_all(attributes) if github?
        containers.with_docker_hub_repo.update_all(attributes) if docker_hub?
      end
    end

    UffizziCore::Credential::RemoveInstallationJob.perform_async(provider_ref) if github?
  end
end
