# frozen_string_literal: true

module UffizziCore::RepoService
  AVAILABLE_KINDS = [
    {
      name: :buildpacks18,
      detect: proc { |**_args| { available: true, args: [] } },
    },
    {
      name: :dockerfile,
      detect: proc { |**args|
        has_dockerfiles = args[:dockerfiles].is_a?(Array) && !args[:dockerfiles].empty?
        multiple_dockerfiles = has_dockerfiles && args[:dockerfiles].length > 1

        {
          available: has_dockerfiles,
          args: !multiple_dockerfiles ? [] : { name: :dockerfile, type: :select, options: args[:dockerfiles] },
        }
      },
    },
    {
      name: :dotnet,
      detect: proc { |**args|
        has_app_runtimes = args[:dotnetruntimes].is_a?(Array) && !args[:dotnetruntimes].empty?
        multiple_app_runtimes = has_app_runtimes && args[:dotnetruntimes].length > 1
        has_csproj = args[:csproj].present?

        {
          available: has_app_runtimes || has_csproj,
          args: !multiple_app_runtimes ? [] : { name: :dotnetruntimes, type: :select, options: args[:dotnetruntimes] },
        }
      },
    },
    {
      name: :gatsby,
      detect: proc { |**args| { available: args[:gatsbyconfig].present?, args: [] } },
    }, {
      name: :barestatic,
      detect: proc { |**args| { available: args[:barestatic].present? && args.filter_map { |k, v| ![:barestatic, :dockerfiles].include?(k) && v.present? }.blank?, args: [] } },
    },
  ].freeze

  class << self
    def nodejs_static?(repo)
      repo.gatsby? || repo.barestatic?
    end

    def cnb?(repo)
      repo.buildpacks18? || repo.dotnet? || nodejs_static?(repo)
    end

    def needs_target_port?(repo)
      return false if repo.nil?

      !repo.dockerfile?
    end

    def credential(repo)
      credentials = repo.project.account.credentials

      case repo.type
      when UffiizziCore::Repo::Github.name
        credentials.github.first
      when UffiizziCore::Repo::DockerHub.name
        credentials.docker_hub.first
      when UffiizziCore::Repo::Azure.name
        credentials.azure.first
      when UffiizziCore::Repo::Google.name
        credentials.google.first
      when UffiizziCore::Repo::Amazon.name
        credentials.amazon.first
      end
    end

    def image_name(repo)
      "e#{repo.container.deployment_id}r#{repo.id}-#{Digest::SHA256.hexdigest("#{self.class}:#{repo.branch}:#{repo.project_id}:#{repo.id}")[0, 10]}"
    end

    def tag(repo)
      repo&.builds&.deployed&.last&.commit || "latest"
    end

    def image(repo)
      repo_credential = credential(repo)

      "#{repo_credential.registry_url}/#{image_name(repo)}"
    end

    def select_default_from(meta)
      return :gatsby if meta[:gatsby][:available]
      return :dotnet if meta[:dotnet][:available]
      return :barestatic if meta[:barestatic][:available]

      :buildpacks18
    end

    def available_repo_kinds(repository_id:, branch:, credential:)
      detections = {
        dotnetruntimes: [],
        gatsbyconfig: false,
        csproj: false,

        go: false,
        ruby: false,
        node: false,
        python: false,
        java: false,
        php: false,
        barestatic: false,
      }

      repo_contents = UffiizziCore::Github::CredentialService.contents(credential, repository_id, ref: branch)
      if repo_contents.length
        if repo_contents.filter_map { |f| f.name == "Godeps" }.present?
          godeps_contents = UffiizziCore::Github::CredentialService.contents(credential, repository_id, path: "Godeps/", ref: branch)
        end

        if repo_contents.filter_map { |f| f.name == "vendor" }.present? && godeps_contents.nil?
          govendor_contents = UffiizziCore::Github::CredentialService.contents(credential, repository_id, path: "vendor/", ref: branch)
        end

        detections[:dotnetruntimes] = repo_contents.filter_map { |f|
          (f.name =~ /^(.+\.)?runtime\.json/ || f.name == "runtime.template.json") && f.name
        }
        detections[:csproj] = repo_contents.filter_map { |f|
          f.name =~ /^.+\.csproj/ && f.name
        }
        detections[:go] = repo_contents.filter_map { |f|
          ["go.mod", "Gopkg.lock", "glide.yaml"].include?(f.name)
        }.present? || godeps_contents&.filter_map { |f| f.name == "Godeps.json" }.present? || govendor_contents&.filter_map { |f| f.name == "vendor.json" }.present?

        [[:ruby, ["Gemfile"]],
         [:node, ["package.json"]],
         [:python, ["requirements.txt", "setup.py", "Pipfile"]],
         [:java, ["pom.xml", "pom.atom", "pom.clj", "pom.groovy", "pom.rb", "pom.scala", "pom.yaml", "pom.yml"]],
         [:php, ["composer.json", "index.php"]],
         [:gatsbyconfig, ["gatsby-config.js"]],
         [:barestatic, ["index.html", "index.htm", "Default.htm"]],].each { |lang| detections[lang[0]] = repo_contents.filter_map { |f| lang[1].include?(f.name) }.present? }
      end

      kinds = AVAILABLE_KINDS.filter_map { |kind|
        detection = kind[:detect].call(detections)

        kind.merge(detection).except(:detect)
      }.map { |kind| [kind[:name], kind.except(:name)] }.to_h

      kinds.merge({ default: select_default_from(kinds) })
    end
  end
end
