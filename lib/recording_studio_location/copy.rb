# frozen_string_literal: true

module RecordingStudioLocation
  # Interface copy lookup. Prefer a host-defined legacy
  # `recording_studio_location.*` key, then the nested
  # `recording_studio.location.*` English shipped by this gem.
  module Copy
    module_function

    # +key+ is relative to both namespaces, e.g. "fields.title" or
    # "search.results_count". Extra I18n options (count, interpolations,
    # string defaults) pass through.
    def t(key, **options)
      relative = relative_key(key)
      defaults = Array(options.delete(:default))

      I18n.t(
        :"recording_studio_location.#{relative}",
        **options,
        default: [:"recording_studio.location.#{relative}", *defaults]
      )
    end

    def relative_key(key)
      key.to_s
         .delete_prefix("recording_studio.location.")
         .delete_prefix("recording_studio_location.")
    end
  end
end
