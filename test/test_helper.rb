# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require_relative '../test/dummy/config/environment'
ActiveRecord::Migrator.migrations_paths = [File.expand_path('../test/dummy/db/migrate', __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path('../db/migrate', __dir__)

Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |f| require f }

require 'factory_bot'
require 'rails/test_help'
require 'webmock/minitest'
require 'mocha/minitest'
require 'minitest/hooks/default'
require 'byebug'
require 'minitest-power_assert'
require 'awesome_print'

FactoryBot.reload
WebMock.disable_net_connect!

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path('fixtures', __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = "#{ActiveSupport::TestCase.fixture_path}/files"
  ActiveSupport::TestCase.fixtures :all
end

FactoryBot.define do
  initialize_with { new(attributes) }
end

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  include Minitest::Hooks
  include ActiveModel::Validations
  include UffizziCore::AuthManagement
end
