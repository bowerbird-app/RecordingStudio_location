# frozen_string_literal: true

require_relative "api/errors"
require_relative "api/crud"
require_relative "api/lookups"

module RecordingStudioLocation
  module Api
    TYPE = "RecordingStudio::Location::Location"
    LOOKUP_CAPABILITY = :location_lookup
    ACTIONS = %i[place_search place_details geocode reverse].freeze
    OUTPUT_KEYS = %i[
      title location_type icon name address_line_1 address_line_2 locality region
      postal_code country_code latitude longitude resolved_icon display_name
      full_address coordinates
    ].freeze

    module_function

    def register!(apis: [:public])
      return unless defined?(::RecordingStudioApi)

      Array(apis).each { |api| register_api(api) }
    end

    def register_api(api)
      register_type(api)
      register_crud_rejects(api)
      ACTIONS.each do |name|
        register_action(api, name)
        register_named_endpoint(api, name)
      end
    end

    def register_type(api)
      ::RecordingStudioApi.register_recordable_type_api(
        TYPE,
        api:,
        operations: [],
        auto_capability_actions: false,
        capability_actions: ACTIONS,
        serializer: method(:serialize_fields),
        output_keys: OUTPUT_KEYS
      )
    end

    def register_crud_rejects(api)
      Crud::OPERATIONS.each do |action|
        next if ::RecordingStudioApi.resource_handler(TYPE, action, api:)

        ::RecordingStudioApi.register_resource_handler(TYPE, action, api:, handler: Crud::Reject)
      end
    end

    def register_action(api, name)
      return if ::RecordingStudioApi.capability_action(name, api:)

      ::RecordingStudioApi.register_capability_action(name, **action_options(api, name))
    end

    def register_named_endpoint(api, name)
      return if ::RecordingStudioApi.registered_endpoint(name, api:)

      ::RecordingStudioApi.register_endpoint(name, **endpoint_options(api, name))
    end

    def action_options(api, name)
      definition = Lookups.definition(name)
      {
        capability: LOOKUP_CAPABILITY, version: "1.0.0", api:,
        http_verb: definition.fetch(:http_verb), required_role: definition.fetch(:required_role),
        handler: definition.fetch(:handler), serializer: definition[:serializer],
        input_contract: definition[:input_contract], openapi: definition.fetch(:openapi)
      }
    end

    def endpoint_options(api, name)
      definition = Lookups.definition(name)
      {
        api:, http_verb: definition.fetch(:http_verb), path: definition.fetch(:path),
        handler: definition.fetch(:handler), serializer: definition[:serializer],
        input_contract: definition[:input_contract], openapi: definition.fetch(:openapi)
      }
    end

    def serialize_fields(location, **)
      location.api_payload
    end
  end
end
