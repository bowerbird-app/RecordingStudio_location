# frozen_string_literal: true

module RecordingStudioLocation
  # Interface copy lookup. Prefer a host-defined legacy
  # `recording_studio_location.*` key via plain `I18n.t` (main's default:
  # chain), then the nested `recording_studio.location.*` gem key via
  # `RecordingStudio.t` so missing active-locale values fall back to loaded
  # English, then caller `default:`, then the registered gem-shipped table.
  module Copy
    module_function

    # +key+ is relative to both namespaces, e.g. "fields.title" or
    # "search.results_count". Extra I18n options (count, interpolations,
    # string defaults) pass through.
    def t(key, **options)
      relative = relative_key(key)
      defaults = Array(options.delete(:default))
      legacy_key = :"recording_studio_location.#{relative}"
      nested_key = :"recording_studio.location.#{relative}"
      locale = options[:locale] || I18n.locale

      # Host / other-namespace keys stay on I18n.t with main's default: chain.
      return I18n.t(legacy_key, **options, default: [nested_key, *defaults]) if I18n.exists?(legacy_key, locale)

      # Only this gem's recording_studio.location.* keys use RecordingStudio.t.
      return RecordingStudio.t(nested_key, **options) if defaults.empty?

      RecordingStudio.t(nested_key, **options, default: defaults)
    end

    def relative_key(key)
      key.to_s
         .delete_prefix("recording_studio.location.")
         .delete_prefix("recording_studio_location.")
    end

    def location_type_not_in_list
      t("errors.location_type_not_in_list")
    end

    def icon_not_in_list
      t("errors.icon_not_in_list")
    end

    def country_code_iso
      t("errors.country_code_iso")
    end

    def must_be_a_number
      t("errors.must_be_a_number")
    end
  end
end
