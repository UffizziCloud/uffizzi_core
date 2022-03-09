# frozen_string_literal: true

class UffizziCore::Github::UserClient
  PER_PAGE = 100

  def initialize(access_token, per_page = PER_PAGE)
    @client = Octokit::Client.new(access_token: access_token, per_page: per_page)
  end

  def branch(repository_id, branch)
    @client.branch(repository_id, branch)
  end

  def search_repositories(query)
    @client.search_repositories(query)
  end
end
