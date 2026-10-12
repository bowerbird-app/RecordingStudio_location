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

    def location_type_not_in_list
      t("errors.location_type_not_in_list", default: "is not in the list of types")
    end

    def icon_not_in_list
      t("errors.icon_not_in_list", default: "is not in the list of icons")
    end

    def country_code_iso
      t("errors.country_code_iso", default: "must be a two-letter ISO country code")
    end

    def must_be_a_number
      t("errors.must_be_a_number", default: "must be a number")
    end
  end
end
