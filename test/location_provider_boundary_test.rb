# frozen_string_literal: true

require "test_helper"

class LocationProviderBoundaryTest < Minitest::Test
  SOURCE_GLOBS = [
    "lib/recording_studio/location.rb",
    "lib/recording_studio/location/**/*.rb",
    "lib/recording_studio/capabilities/location.rb",
    "app/models/recording_studio/location/**/*.rb",
    "app/views/recording_studio_location/**/*.erb",
    "db/migrate/*recording_studio_locations*"
  ].freeze

  FORBIDDEN = [
    "mapbox",
    "google",
    "here.com",
    "apple maps",
    "postgis",
    "Net::HTTP",
    "geocoder gem",
    "Faraday"
  ].freeze

  def test_core_files_do_not_reference_a_map_or_geocoding_provider
    files = SOURCE_GLOBS.flat_map { |pattern| Dir[File.expand_path("../#{pattern}", __dir__)] }
    refute_empty files

    files.each do |path|
      content = File.read(path).downcase
      FORBIDDEN.each do |needle|
        refute_includes content, needle.downcase, "#{path} mentions #{needle}"
      end
    end
  end

  def test_geocoder_assignment_is_stored_and_not_required
    previous = RecordingStudio::Location.geocoder
    adapter = Object.new
    RecordingStudio::Location.geocoder = adapter

    assert_same adapter, RecordingStudio::Location.geocoder
    assert_same adapter, RecordingStudioLocation.configuration.geocoder
    assert_nil RecordingStudio::Location.country_name(nil)
    assert_equal "Australia", RecordingStudio::Location.country_name("au")
  ensure
    RecordingStudio::Location.geocoder = previous
  end

  def test_migration_uses_decimal_coordinates_without_a_spatial_type
    migration = File.read(
      File.expand_path("../db/migrate/20261002000001_create_recording_studio_locations.rb", __dir__)
    )

    assert_includes migration, "create_table :recording_studio_locations"
    assert_includes migration, "t.decimal :latitude, precision: 10, scale: 7"
    assert_includes migration, "t.decimal :longitude, precision: 11, scale: 7"
    assert_includes migration, "add_index :recording_studio_locations, :country_code"
    refute_includes migration, "postgis"
    refute_includes migration, "st_point"
  end

  def test_location_declaration_does_not_hard_code_host_parents
    source = File.read(File.expand_path("../app/models/recording_studio/location/location.rb", __dir__))

    assert_includes source, 'recording_studio_recordable label: "Location", plural_label: "Locations", root: false'
    refute_includes source, "allowed_parent_types"
    refute_includes source, "PressKit"
    refute_includes source, "Business"
  end
end
