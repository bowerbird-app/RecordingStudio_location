# frozen_string_literal: true

require "test_helper"
require File.expand_path("../app/controllers/recording_studio_location/authentication", __dir__)

class AuthenticationTest < Minitest::Test
  class Harness
    include RecordingStudioLocation::Authentication

    attr_reader :status

    def initialize
      @performed = false
    end

    def head(status)
      @status = status
      @performed = true
    end

    def performed?
      @performed
    end

    def respond_to?(name, include_private = false)
      return false if name.to_sym == :authenticate_user!

      super
    end
  end

  def setup
    @previous = RecordingStudioLocation.configuration.authenticate
  end

  def teardown
    RecordingStudioLocation.configuration.authenticate = @previous
  end

  def test_identity_callback_can_halt_without_accessible
    RecordingStudioLocation.configuration.authenticate = ->(controller) { controller.head :forbidden }
    harness = Harness.new

    harness.send(:authenticate_location_request!)

    assert_equal :forbidden, harness.status
  end

  def test_signed_in_request_is_forbidden_when_accessible_is_missing
    RecordingStudioLocation.configuration.authenticate = ->(*) {}
    harness = Harness.new

    harness.send(:authenticate_location_request!)

    assert_equal :forbidden, harness.status
    refute defined?(RecordingStudioAccessible)
  end

  def test_missing_identity_is_unauthorized
    RecordingStudioLocation.configuration.authenticate = nil
    harness = Harness.new

    harness.send(:authenticate_location_request!)

    assert_equal :unauthorized, harness.status
  end
end
