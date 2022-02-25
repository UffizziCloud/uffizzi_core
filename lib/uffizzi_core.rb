# frozen_string_literal: true

require 'uffizzi_core/version'
require 'uffizzi_core/engine'

require 'aasm'
require 'active_model_serializers'
require 'ancestry'
require 'enumerize'
require 'pg'
require 'responders'
require 'rolify'
require 'virtus'
require 'rswag-api'
require 'rswag-ui'

module UffizziCore
  mattr_accessor :table_names, default: {}
end
