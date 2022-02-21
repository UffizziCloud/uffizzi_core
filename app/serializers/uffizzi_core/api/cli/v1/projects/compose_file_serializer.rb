# frozen_string_literal: true

class UffizziCore::Api::Cli::V1::Projects::ComposeFileSerializer < UffizziCore::BaseSerializer
  attributes :id, :source, :path, :auto_deploy, :state, :payload, :content
end
