# frozen_string_literal: true

class UffizziCore::Api::Cli::V1::UserSerializer < UffizziCore::BaseSerializer
  has_many :accounts
end
