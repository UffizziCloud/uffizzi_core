# frozen_string_literal: true

class UffizziCore::Api::Cli::V1::ComposeFile::GithubForm
  include UffizziCore::ApplicationFormWithoutActiveRecord

  attribute :credential, UffizziCore::Credential
  attribute :compose_content_data, Hash
  attribute :compose_data, Hash
  attribute :compose_dependencies, Array
  attribute :compose_repositories, Array
  attribute :content, String

  validates :credential, presence: { message: 'Invalid credential: Github' }
  validates :content, presence: true

  validate :check_compose_parsed_data, if: -> { errors[:content].empty? }
  validate :check_repositories, if: -> { credential.present? && errors[:content].empty? }
  validate :check_branches, if: -> { credential.present? && errors[:content].empty? }

  def check_compose_parsed_data
    compose_content = Base64.decode64(content)
    self.compose_data = UffizziCore::ComposeFileService.parse(compose_content)
  rescue UffizziCore::ComposeFile::ParseError => e
    errors.add(:content, e.message)
  end

  def check_repositories
    self.compose_repositories = UffizziCore::ComposeFileService.load_repositories(compose_data, credential)
  rescue UffizziCore::ComposeFile::NotFoundError => e
    errors.add(:content, e.message)
  end

  def check_branches
    return if compose_repositories.blank?

    UffizziCore::ComposeFileService.check_github_branches(compose_data, compose_repositories, credential)
  rescue UffizziCore::ComposeFile::NotFoundError => e
    errors.add(:content, e.message)
  end

  def build_compose_dependencies; end
end
