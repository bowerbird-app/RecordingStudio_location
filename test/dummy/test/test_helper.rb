# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"
require_relative "support/accessible_grants"

class ActionDispatch::IntegrationTest
  include AccessibleGrants
end
