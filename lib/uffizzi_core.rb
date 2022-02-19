# frozen_string_literal: true

require 'uffizzi_core/version'
require 'uffizzi_core/engine'

require 'aasm'
require 'ancestry'
require 'enumerize'
require 'pg'
require 'responders'
require 'rolify'
require 'virtus'

module UffizziCore
  mattr_accessor :table_names, default: {}
end
