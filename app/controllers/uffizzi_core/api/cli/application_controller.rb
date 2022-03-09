# frozen_string_literal: true

class UffizziCore::Api::Cli::ApplicationController < ActionController::Base
  include UffizziCore::ResponseService
  include UffizziCore::AuthManagement

  protect_from_forgery with: :exception
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  before_action :authenticate_request!
  skip_before_action :verify_authenticity_token

  respond_to :json

  def self.responder
    UffizziCore::JsonResponder
  end

  def render_not_found
    render json: { errors: { title: ['Resource Not Found'] } }, status: :not_found
  end
end
