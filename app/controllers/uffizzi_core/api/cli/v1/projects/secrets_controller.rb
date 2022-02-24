# frozen_string_literal: true

# @resource Uffizzi-secrets
class UffizziCore::Api::Cli::V1::Projects::SecretsController < UffizziCore::Api::Cli::V1::Projects::ApplicationController
  # Get projects of current user
  #
  # @path [GET] /api/cli/v1/projects/{project_slug}/secrets
  #
  # @response [object<secrets: Array<object<name: string>> >] 200 OK
  # @response 401 Not authorized
  def index
    project_secrets = resource_project.secrets.present? ? resource_project.secrets : []
    secrets = project_secrets.map { |secret| { name: secret['name'] } }

    render json: { secrets: secrets }, status: :ok
  end

  # Add secret to project
  #
  # @path [POST] /api/cli/v1/projects/{project_slug}/secrets
  #
  # @parameter secrets(required,body) [Array<object <name: string, value: string>>]
  #
  # @response [object<secrets: Array<object<name: string>>>] 201 Created
  # @response 401 Not authorized

  def bulk_create
    project_form = resource_project.becomes(UffizziCore::Api::Cli::V1::Project::UpdateForm)
    project_form.assign_secrets!(secrets_params)
    return render json: { errors: project_form.errors }, status: :unprocessable_entity unless project_form.save

    UffizziCore::ProjectService.update_compose_secrets(project_form)
    secrets = project_form.secrets.map { |secret| { name: secret['name'] } }

    render json: { secrets: secrets }, status: :created
  end

  # Delete a secret from project by id
  #
  # @path [GET] /api/cli/v1/projects/{project_slug}/secrets/{id}
  #
  # @parameter id(required,path) [string]
  #
  # @response 204 No Content
  # @response 401 Not authorized
  def destroy
    secret_name = CGI.unescape(params[:id])
    UffizziCore::ProjectService.delete_secret(secret_name, resource_project)

    head :no_content
  end

  private

  def secrets_params
    params.require(:secrets)
  end
end
