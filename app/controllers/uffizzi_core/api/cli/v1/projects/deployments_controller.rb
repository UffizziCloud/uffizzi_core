# frozen_string_literal: true

# @resource Deployment

class UffizziCore::Api::Cli::V1::Projects::DeploymentsController < UffizziCore::Api::Cli::V1::Projects::ApplicationController
  # Get a list of active deployements for a project
  #
  # @path [GET] /api/cli/v1/projects/{project_slug}/deployments
  #
  # @parameter project_slug(required,path) [string] The slug for the project
  #
  # @response [Array<Deployment>] 200 OK
  # @response 401 Not authorized
  def index
    respond_with deployments
  end

  # Get deployment information by id
  #
  # @path [GET] /api/cli/v1/projects/{project_slug}/deployments/{id}
  #
  # @parameter project_slug(required,path) [string] The slug for the project
  #
  # @response [Deployment] 200 OK
  # @response [object<errors: object<title: string>>] 404 Not found
  # @response 401 Not authorized
  def show
    respond_with deployment
  end

  # Create a deployment from a compose file
  #
  # @path [POST] /api/cli/v1/projects/{project_slug}/deployments
  #
  # @parameter project_slug(required,path) [string] The slug for the project
  # @parameter params(required,body)   [object<compose_file: object<path: string, source: string, content: string>,
  # dependencies:  Array<object<path: string, source: string, content: string>>>]
  #
  # @response [Deployment] 201 OK
  # @response [object<errors: object<state: string>>] 422 Unprocessable Entity
  # @response [object<errors: object<title: string>>] 404 Not found
  # @response 401 Not authorized
  def create
    compose_file, errors = find_or_create_compose_file
    return render_invalid_file if compose_file.invalid_file?
    return render_errors(errors) if errors.present?

    errors = check_credentials(compose_file)
    return render_errors(errors) if errors.present?

    deployment = UffizziCore::DeploymentService.create_from_compose(compose_file, resource_project, current_user)

    respond_with deployment
  end

  # @path [POST] /api/cli/v1/projects/{project_slug}/deployments/{id}/deploy_containers
  #
  # @parameter project_slug(required,path) [string] The slug for the project
  # @parameter id(required,path) [string] The id of the deployment
  #
  # @response 204 No Content
  # @response [object<errors: object<title: string>>] 404 Not found
  # @response 401 Not authorized
  def deploy_containers
    deployment = resource_project.deployments.active.find(params[:id])

    deployment.update(deployed_by: current_user)

    resource_project.config_files.by_deployment(deployment).each do |config_file|
      UffizziCore::ConfigFile::ApplyJob.perform_async(deployment.id, config_file.id)
    end

    UffizziCore::Deployment::DeployContainersJob.perform_async(deployment.id)
  end

  # Disable deployment by id
  #
  # @path [DELETE] /api/cli/v1/projects/{project_slug}/deployments/{id}
  #
  # @parameter project_slug(required,path) [string] The slug for the project
  #
  # @response 204 No Content
  # @response 401 Not authorized
  def destroy
    UffizziCore::DeploymentService.disable!(deployment)

    head :no_content
  end

  private

  def deployment
    @deployment ||= deployments.find(params[:id])
  end

  def find_or_create_compose_file
    existing_compose_file = resource_project.compose_file
    if compose_file_params.present?
      create_params = {
        project: resource_project,
        user: current_user,
        compose_file_params: compose_file_params,
        dependencies: dependencies_params[:dependencies] || [],
      }

      kind = UffizziCore::ComposeFile.kind.temporary
      UffizziCore::Cli::ComposeFileService.create(create_params, kind)
    else
      raise ActiveRecord::RecordNotFound if existing_compose_file.blank?

      errors = []
      [existing_compose_file, errors]
    end
  end

  def check_credentials(compose_file)
    credentials = resource_project.account.credentials
    check_credentials_form = UffizziCore::Api::Cli::V1::ComposeFile::CheckCredentialsForm.new
    check_credentials_form.compose_file = compose_file
    check_credentials_form.credentials = credentials
    return check_credentials_form.errors if check_credentials_form.invalid?

    nil
  end

  def deployments
    @deployments ||= resource_project.deployments.active
  end

  def deployment_params
    params.required(:deployment)
  end

  def compose_file_params
    params[:compose_file]
  end

  def dependencies_params
    params.permit(dependencies: [:name, :path, :source, :content])
  end

  def render_invalid_file
    render json: { errors: { state: [I18n.t('compose.invalid_file')] } }, status: :unprocessable_entity
  end
end
