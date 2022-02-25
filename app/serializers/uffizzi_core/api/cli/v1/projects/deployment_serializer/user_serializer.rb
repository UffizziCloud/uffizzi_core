
# frozen_string_literal: true

class UffizziCore::Api::Cli::V1::Projects::DeploymentSerializer::UserSerializer < UffizziCore::BaseSerializer
  include UserConcern

  type :user

  attributes :id, :kind, :email, :avatar_url

  def kind
    :internal
  end
end
