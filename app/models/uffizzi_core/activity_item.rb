# frozen_string_literal: true

class UffizziCore::ActivityItem < UffizziCore::ApplicationRecord
  include UffizziCore::ActivityItemRepo

  self.table_name = Rails.application.config.uffizzi_core[:table_names][:activity_items]

  belongs_to :deployment
  belongs_to :container
  belongs_to :build, optional: true

  has_many :events, dependent: :destroy

  scope :docker, -> {
    where(type: UffizziCore::ActivityItem::Docker.name)
  }

  scope :github, -> {
    where(type: UffizziCore::ActivityItem::Github.name)
  }

  def github?
    type == UffizziCore::ActivityItem::Github.name
  end

  def docker?
    type == UffizziCore::ActivityItem::Docker.name
  end

  def image
    [namespace, name].compact.join('/')
  end

  def full_image
    return "#{image}:#{branch}" if github?
    return "#{image}:#{tag}" if docker?

    ''
  end
end
