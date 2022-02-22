# frozen_string_literal: true

class UffizziCore::ComposeFile::ContainerService
  class << self
    def github?(container)
      repository_url = container.dig(:build, :repository_url)

      repository_url.present? && repository_url.include?('github.com')
    end

    def azure?(container)
      registry_url = container.dig(:image, :registry_url)

      registry_url.present? && registry_url.include?('azurecr.io')
    end

    def google?(container)
      registry_url = container.dig(:image, :registry_url)

      registry_url.present? && registry_url.include?('gcr.io')
    end

    def docker_hub?(container)
      registry_url = container.dig(:image, :registry_url)
      repository_url = container.dig(:build, :repository_url)

      registry_url.nil? && repository_url.nil?
    end

    def has_secret?(container, secret)
      container['secret_variables'].any? { |container_secret| container_secret['name'] == secret['name'] }
    end

    def update_secret(container, secret)
      secret_index = container['secret_variables'].find_index { |container_secret| container_secret['name'] == secret['name'] }
      container['secret_variables'][secret_index] = secret

      container
    end
  end
end
