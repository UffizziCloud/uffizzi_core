# frozen_string_literal: true

class UffizziCore::Api::Cli::V1::Project::UpdateForm < UffizziCore::Project
  include UffizziCore::ApplicationForm

  permit :name, :slug, :description, secrets: [:name, :value]

  validates :name, presence: true, uniqueness: { scope: :account }
  validates :slug, presence: true, uniqueness: true

  validate :check_duplicates

  def assign_secrets!(new_secrets)
    existing_secrets = secrets.presence || []

    self.secrets = existing_secrets.union(new_secrets)
  end

  def delete_secret!(secret_name)
    existing_secrets = secrets.presence || []

    self.secrets = existing_secrets.reject { |secret| secret['name'] == secret_name }
  end

  private

  def check_duplicates
    duplicates = []
    groupped_secrets = secrets.group_by { |secret| secret['name'] }
    groupped_secrets.each_pair do |key, value|
      duplicates << key if value.size > 1
    end

    errors.add(:secrets, :duplicates_exist, secrets: duplicates.join(', ')) if duplicates.present?
  end
end
