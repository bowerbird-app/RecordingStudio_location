# frozen_string_literal: true

require "test_helper"
require "yaml"

class LocalesTest < ActiveSupport::TestCase
  setup do
    @original_load_path = I18n.load_path.dup
    load_engine_locales!
  end

  teardown do
    I18n.load_path = @original_load_path
    I18n.backend.load_translations
  end

  FIELD_KEYS = {
    "title" => "Title",
    "title_placeholder" => "Office HQ",
    "title_help" => "Optional. Your name for this place.",
    "location_type" => "Type",
    "icon" => "Icon",
    "name" => "Name",
    "name_placeholder" => "Melbourne Convention Centre",
    "name_help" => "Optional. The venue or place name.",
    "address_line_1" => "Address line 1",
    "address_line_1_placeholder" => "12 Smith Street",
    "address_line_2" => "Address line 2",
    "locality" => "Locality",
    "locality_placeholder" => "Fitzroy",
    "region" => "Region",
    "region_placeholder" => "Victoria",
    "postal_code" => "Postal code",
    "postal_code_placeholder" => "3065",
    "country" => "Country",
    "country_placeholder" => "Select a country",
    "country_not_set" => "Not set",
    "latitude" => "Latitude",
    "latitude_placeholder" => "-37.798",
    "latitude_help" => "Optional.",
    "longitude" => "Longitude",
    "longitude_placeholder" => "144.978",
    "longitude_help" => "Optional. Leave both blank when you do not have coordinates."
  }.freeze

  SEARCH_KEYS = {
    "label" => "Location",
    "placeholder" => "Search for a place or address",
    "searching" => "Searching",
    "add_manually" => "Add address manually",
    "clear" => "Clear location",
    "done" => "Done",
    "modal_title" => "Enter address",
    "summary_empty" => "No place selected yet."
  }.freeze

  MAP_KEYS = {
    "title" => "Map of this location"
  }.freeze

  LOCATION_TYPE_KEYS = {
    "office" => "Office",
    "home" => "Home",
    "venue" => "Venue",
    "other" => "Other"
  }.freeze

  ICON_KEYS = {
    "home" => "Home",
    "building-office" => "Building",
    "map-pin" => "Pin",
    "star" => "Star",
    "briefcase" => "Briefcase"
  }.freeze

  test "engine ships only english locale files" do
    files = Dir[File.join(engine_locales_dir, "*")].map { |path| File.basename(path) }

    assert_equal ["en.yml"], files.sort
  end

  test "rails i18n load path includes the nested english locale file" do
    locale_path = File.join(engine_locales_dir, "en.yml")

    assert_includes I18n.load_path.map { |path| File.expand_path(path) }, File.expand_path(locale_path)
  end

  test "nested english interface keys resolve without missing translations" do
    I18n.with_locale(:en) do
      assert_section_translations("fields", FIELD_KEYS)
      assert_section_translations("search", SEARCH_KEYS)
      assert_section_translations("map", MAP_KEYS)
      assert_section_translations("location_types", LOCATION_TYPE_KEYS)
      assert_section_translations("icons", ICON_KEYS)
      assert_interpolated_translations
    end
  end

  test "en.yml nests keys under recording_studio.location" do
    tree = locale_tree(File.join(engine_locales_dir, "en.yml"), "en")
           .fetch("recording_studio")
           .fetch("location")

    assert_equal FIELD_KEYS, tree.fetch("fields").transform_keys(&:to_s)
    assert_equal SEARCH_KEYS, tree.fetch("search").transform_keys(&:to_s)
    assert_equal MAP_KEYS, tree.fetch("map").except("title_with_coordinates").transform_keys(&:to_s)
    assert_equal LOCATION_TYPE_KEYS, tree.fetch("location_types").transform_keys(&:to_s)
    assert_equal ICON_KEYS, tree.fetch("icons").transform_keys(&:to_s)
  end

  test "gem does not ship a legacy top-level locale file" do
    legacy_path = File.join(engine_locales_dir, "recording_studio_location.en.yml")

    refute File.exist?(legacy_path)
  end

  private

  def engine_locales_dir
    File.expand_path("../config/locales", __dir__)
  end

  def load_engine_locales!
    paths = Dir[File.join(engine_locales_dir, "*.{yml,rb}")].map { |path| File.expand_path(path) }
    I18n.load_path |= paths
    I18n.backend.load_translations
  end

  def locale_tree(path, locale)
    YAML.safe_load_file(path, aliases: true).fetch(locale)
  end

  def assert_translation(full_key, english)
    translation = I18n.t(full_key, default: nil)

    assert_equal english, translation, "#{full_key} should resolve to #{english.inspect}"
    assert_equal english, I18n.t(full_key, raise: true)
  end

  def assert_section_translations(section, keys)
    keys.each do |key, english|
      assert_translation("recording_studio.location.#{section}.#{key}", english)
    end
  end

  def assert_interpolated_translations
    assert_equal(
      "Map of -37.825500, 144.953100",
      I18n.t(
        "recording_studio.location.map.title_with_coordinates",
        latitude: "-37.825500",
        longitude: "144.953100",
        raise: true
      )
    )
  end
end
