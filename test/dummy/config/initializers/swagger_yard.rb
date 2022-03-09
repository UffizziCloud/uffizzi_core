# frozen_string_literal: true

require 'swagger_yard'

SwaggerYard.configure do |config|
  config.api_version = '1.0'

  config.title = 'Uffizzi docs'
  config.description = 'Your API does this'

  # where your actual api is hosted from
  config.api_base_path = 'http://lvh.me:7000'

  # Where to find controllers (can be an array of paths/globs)
  config.controller_path = File.expand_path('app/controllers/uffizzi_core/api/**/*', __dir__)
  config.model_path = File.expand_path('app/models/uffizzi_core/**/*', __dir__)

  # Whether to include controller methods marked as private
  # (either with ruby `private` or YARD `# @visibility private`
  # Default: true
  config.include_private = false
end
