# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"
require_relative "support/accessible_grants"

class ActiveSupport::TestCase
  include AccessibleGrants

  setup do
    @previous_studio_actor = Current.actor if defined?(Current)
  end

  teardown do
    Current.actor = @previous_studio_actor if defined?(Current)
  end
end

class ActionDispatch::IntegrationTest
  include AccessibleGrants
end
