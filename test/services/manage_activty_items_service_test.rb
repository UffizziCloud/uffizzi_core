# frozen_string_literal: true

require 'test_helper'

class UffizziCore::ManageActivityItemsServiceTest < ActiveSupport::TestCase
  setup do
    @user = create(:user, :with_organizational_account)
    @project = create(:project, account: @user.organizational_account)
  end

  test '#container_status_items - deployment has no containers' do
    deployment = create(:deployment, project: @project)
    stubbed_response_containers = []

    namespace = UffizziCore::Converters.deep_lower_camelize_keys(
      {
        metadata: {
          annotations: {
            network_connectivity: {}.to_json,
          },
        },
      },
    )

    stub_request(:get, "#{Settings.controller.url}/nodes")
    stub_request(:get, "#{Settings.controller.url}/deployments/#{deployment.id}/containers")
      .to_return(status: 200, body: stubbed_response_containers.to_json)
    stub_request(:get, "#{Settings.controller.url}/deployments/#{deployment.id}").to_return(status: 200, body: namespace.to_json)

    service = UffizziCore::ManageActivityItemsService.new(deployment)
    container_status_items = service.container_status_items

    assert { container_status_items.empty? }
  end

  test '#container_status_items - deployment has containers' do
    create(:credential, :github, account: @user.organizational_account)
    deployment = create(:deployment, project: @project)
    repo = create(:repo, :github, project: @project)
    create(:build, :successful, :deployed, repo: repo)
    container = create(:container, :active, :with_public_port, repo: repo, deployment: deployment)

    node_name = generate(:name)
    current_time = DateTime.now.iso8601
    pod_name = UffizziCore::ContainerService.pod_name(container)

    pods = UffizziCore::Converters.deep_lower_camelize_keys(
      [
        {
          metadata: {
            name: "#{Settings.controller.namespace_prefix}#{generate(:name)}",
            creation_timestamp: current_time,
          },
          spec: {
            node_name: node_name,
          },
          status: {
            container_statuses: [
              {
                name: pod_name,
                restart_count: 0,
                image: container.name,
                state: {
                  running: {
                    started_at: current_time,
                  },
                },
              },
            ],
          },
        },
      ],
    )

    network_connectivity = {
      'containers' => {
        container.id.to_s => {
          'service' => {
            'status' => 'pending',
          },
          'ingress' => {
            'status' => 'pending',
          },
        },
      },
    }

    namespace = UffizziCore::Converters.deep_lower_camelize_keys(
      {
        metadata: {
          annotations: {
            network_connectivity: network_connectivity.to_json,
          },
        },
      },
    )

    stub_request(:get, "#{Settings.controller.url}/deployments/#{deployment.id}/containers")
      .to_return(status: 200, body: pods.to_json)
    stub_request(:get, "#{Settings.controller.url}/deployments/#{deployment.id}").to_return(status: 200, body: namespace.to_json)

    service = UffizziCore::ManageActivityItemsService.new(deployment)
    container_status_items = service.container_status_items

    assert { container_status_items[0][:status] == UffizziCore::Event.state.deploying }
  end
end
