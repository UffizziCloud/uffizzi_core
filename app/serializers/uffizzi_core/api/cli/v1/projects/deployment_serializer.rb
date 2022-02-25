
# frozen_string_literal: true

class UffizziCore::Api::Cli::V1::Projects::DeploymentSerializer < UffizziCore::BaseSerializer
  attributes :id,
             :kind,
             :project_id,
             :created_at,
             :updated_at,
             :state,
             :preview_url,
             :tag,
             :branch,
             :commit,
             :image_id,
             :ingress_container_ready,
             :ingress_container_state,
             :creation_source

  has_many :containers

  belongs_to :deployed_by

  def deployed_by
    object.deployed_by
  end

  def containers
    object.containers.active
  end

  def preview_url
    DeploymentService.build_preview_url(object)
  end

  def tag
    object.ingress_container&.tag
  end

  def branch
    object.ingress_container&.repo&.branch
  end

  def commit
    object.ingress_container&.repo&.builds&.deployed&.last&.commit.to_s.slice(0..5)
  end

  def image_id
    object.ingress_container&.repo&.name
  end

  def ingress_container_ready
    !!object.ingress_container&.activity_items&.last&.events&.last&.deployed?
  end

  def ingress_container_state
    count_activity_items = object.ingress_container&.activity_items&.count
    last_event = object.ingress_container&.activity_items&.last&.events&.last

    case last_event&.state
    when Event.state.deployed
      :deployed
    when Event.state.failed, Event.state.timeout, Event.state.cancelled
      :failed
    else
      count_activity_items.to_i > 1 ? :updating : :pending
    end
  end
end
