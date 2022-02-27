# frozen_string_literal: true

require 'uffizzi_core/version'
require 'uffizzi_core/engine'

require 'aasm'
require 'active_model_serializers'
require 'ancestry'
require 'hashie'
require 'google/cloud/dns'
require 'enumerize'
require 'pg'
require 'responders'
require 'rolify'
require 'sidekiq'
require 'virtus'

module UffizziCore
  mattr_accessor :table_names, default: {}
end
