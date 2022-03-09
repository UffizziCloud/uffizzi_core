# frozen_string_literal: true

class UffizziCore::Github::CredentialService
  class << self
    def search_repositories(credential, search_query)
      result = client(credential).search_repositories(search_query)

      result[:items]
    rescue Octokit::UnprocessableEntity
      []
    end

    def branch(credential, repository_id, branch)
      client(credential).branch(repository_id, branch)
    rescue Octokit::Unauthorized
      Rails.logger.warn("broken credentials, branch credential_id=#{credential.id}")
      credential.unauthorize! unless credential.unauthorized?
      raise
    end

    def contents(credential, repository_id, options)
      client(credential).contents(repository_id, options)
    rescue Octokit::Unauthorized
      Rails.logger.warn("broken credentials, contents credential_id=#{credential.id}")
      credential.unauthorize! unless credential.unauthorized?
      raise
    end

    private

    def client(credential)
      UffizziCore::Github::UserClient.new(credential.password)
    end
  end
end
