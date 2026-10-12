# frozen_string_literal: true

require "test_helper"

class CopyTest < ActiveSupport::TestCase
  setup do
    @original_load_path = I18n.load_path.dup
    locale_path = File.expand_path("../config/locales/en.yml", __dir__)
    I18n.load_path |= [locale_path]
    I18n.backend.load_translations
  end

  teardown do
    I18n.load_path = @original_load_path
    I18n.backend.load_translations
  end

  test "nested english renders when the host has no legacy override" do
    I18n.with_locale(:en) do
      assert_equal "Title", RecordingStudioLocation::Copy.t("fields.title")
      assert_equal "Clear location", RecordingStudioLocation::Copy.t("search.clear")
      assert_equal(
        "Map of -37.825500, 144.953100",
        RecordingStudioLocation::Copy.t(
          "map.title_with_coordinates",
          latitude: "-37.825500",
          longitude: "144.953100"
        )
      )
    end
  end

  test "host-defined legacy key wins over nested english" do
    I18n.backend.store_translations(
      :en,
      recording_studio_location: {
        fields: { title: "Place name" },
        search: { clear: "Wipe place" }
      }
    )

    I18n.with_locale(:en) do
      assert_equal "Place name", RecordingStudioLocation::Copy.t("fields.title")
      assert_equal "Wipe place", RecordingStudioLocation::Copy.t("search.clear")
      # Unoverridden keys still use nested English.
      assert_equal "Location", RecordingStudioLocation::Copy.t("search.label")
    end
  end

  test "legacy host override wins for type labels icon labels and map title" do
    I18n.backend.store_translations(
      :en,
      recording_studio_location: {
        location_types: { office: "Legacy Office" },
        icons: { home: "Legacy Home" },
        map: { title: "Legacy Map of this location" }
      }
    )

    I18n.with_locale(:en) do
      assert_equal "Legacy Office",
                   RecordingStudioLocation.configuration.location_type_label("office")
      assert_equal "Legacy Home",
                   RecordingStudioLocation.configuration.icon_label("home")
      assert_equal "Legacy Map of this location",
                   RecordingStudioLocation::Copy.t("map.title", default: "Map of this location")
      # Unoverridden nested English still wins when no legacy key is set.
      assert_equal "Venue",
                   RecordingStudioLocation.configuration.location_type_label("venue")
      assert_equal "Pin",
                   RecordingStudioLocation.configuration.icon_label("map-pin")
    end
  end

  test "type and icon labels use nested english when host has no legacy override" do
    I18n.with_locale(:en) do
      assert_equal "Office",
                   RecordingStudioLocation.configuration.location_type_label("office")
      assert_equal "Home",
                   RecordingStudioLocation.configuration.icon_label("home")
      assert_equal "Map of this location",
                   RecordingStudioLocation::Copy.t("map.title", default: "Map of this location")
    end
  end

  test "non-english locale resolves type and icon labels through copy" do
    previous_available = I18n.available_locales
    I18n.available_locales = Array(I18n.available_locales) | %i[en fr]
    I18n.backend.store_translations(
      :fr,
      recording_studio: {
        location: {
          location_types: { office: "Bureau" },
          icons: { home: "Maison" },
          map: { title: "Carte de cet emplacement" }
        }
      }
    )

    I18n.with_locale(:fr) do
      assert_equal "Bureau",
                   RecordingStudioLocation.configuration.location_type_label("office")
      assert_equal "Maison",
                   RecordingStudioLocation.configuration.icon_label("home")
      assert_equal "Carte de cet emplacement",
                   RecordingStudioLocation::Copy.t("map.title", default: "Map of this location")
    end
  ensure
    I18n.available_locales = previous_available
  end
end
