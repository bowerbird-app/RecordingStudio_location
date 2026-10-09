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
end
