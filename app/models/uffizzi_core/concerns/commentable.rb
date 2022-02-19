# frozen_string_literal: true

module UffizziCore::Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, as: :commentable
  end
end
