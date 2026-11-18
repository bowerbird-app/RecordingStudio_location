# frozen_string_literal: true

require_relative "api/errors"
require_relative "api/lookups"

module RecordingStudioLocation
  module Api
    TYPE = "RecordingStudio::Location::Location"
    ENDPOINTS = %i[
      location_geocode
      location_reverse
    ].freeze

    module_function

    def register!
      return unless defined?(::RecordingStudioApi)

      version = Gem::Version.new(::RecordingStudioApi::VERSION)
      unless Gem::Requirement.new(">= 1.1", "< 2.0").satisfied_by?(version)
        raise ::RecordingStudioApi::ConfigurationError,
              "Recording Studio Location needs Recording Studio API >= 1.1, < 2.0"
      end

      ::RecordingStudioApi.configuration.each_api { |api| register_api(api) if register_on_api?(api) }
    end

    def register_on_api?(api)
      choice = RecordingStudioLocation.configuration.register_api_endpoints_on
      return true if choice == :all

      apis = ::RecordingStudioApi.configuration
      target = apis.canonical_api_name(api.name)
      choice.any? { |name| apis.canonical_api_name(name) == target }
    end

    def register_api(api)
      ENDPOINTS.each { |name| register_named_endpoint(api, name) }
    end

    def register_named_endpoint(api, name)
      definition = Lookups.definition(name)
      existing = ::RecordingStudioApi.registered_endpoint(name, api: api.name)
      if existing
        unless ours?(existing, definition)
          raise ::RecordingStudioApi::ConfigurationError, "API endpoint #{name} is already registered"
        end

        return
      end

      ::RecordingStudioApi.register_endpoint(name, **endpoint_options(api, definition))
    end

    def ours?(existing, definition)
      existing.handler == definition.fetch(:handler) &&
        existing.http_verb == definition.fetch(:http_verb) &&
        existing.path == definition.fetch(:path) &&
        existing.recordable_type == TYPE &&
        existing.required_role == definition.fetch(:required_role)
    end

    def endpoint_options(api, definition)
      {
        api: api.name, http_verb: definition.fetch(:http_verb), path: definition.fetch(:path),
        handler: definition.fetch(:handler), serializer: definition[:serializer],
        input_contract: definition[:input_contract], openapi: definition.fetch(:openapi),
        recordable_type: TYPE, required_role: definition.fetch(:required_role)
      }
    end
  end
end
