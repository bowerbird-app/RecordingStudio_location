# frozen_string_literal: true

require "test_helper"

class LookupDescriptionsTest < Minitest::Test
  Lookups = RecordingStudioLocation::Api::Lookups

  SUMMARIES = {
    location_geocode: "Look up coordinates",
    location_reverse: "Fill address from coordinates"
  }.freeze

  GROUP = "Location"

  FORBIDDEN = [
    "Path parameter id.",
    "geocode!",
    "reverse!",
    "Authorize :edit",
    "inside a location revision",
    "paid traffic"
  ].freeze

  def test_tool_descriptions_say_what_the_lookup_does
    each_tool do |name, openapi, _contract|
      description = openapi.fetch(:description)
      summary = openapi.fetch(:summary)

      FORBIDDEN.each do |phrase|
        refute_includes description, phrase, name.to_s
        refute_includes summary, phrase, name.to_s
      end
      assert_includes description, "You need edit access to the location."
      assert_includes description, "may cost money"
      assert_includes description, "a new revision of the location"
      assert_match(/stays? in history/, description)
      assert_includes description, "When no geocoder is configured, the call fails with Missing."
      assert_includes description, "Assign RecordingStudio::Location.geocoder before geocoding"
      assert_includes description, Lookups.response_description
      assert_includes description, "The latitude and longitude fields are numbers, or null when absent."
      assert_equal SUMMARIES.fetch(name), summary
      assert_equal [GROUP], openapi.fetch(:tags)
      refute_match(/\.\z/, summary)
      assert_sentence description
      refute_equal name.to_s.tr("_", " "), description
    end
  end

  def test_every_input_has_a_full_sentence_description
    each_tool do |_name, openapi, contract|
      parameters = Array(openapi.fetch(:parameters))
      id = parameters.find { |parameter| parameter.fetch(:name) == "id" }

      assert_equal Lookups::RECORDING_ID_DESCRIPTION, id.fetch(:description)
      assert_sentence id.fetch(:description)
      refute_includes id.fetch(:description), "Path parameter"

      contract.fetch(:fields).each_value do |rules|
        assert_sentence rules.fetch(:description)
        refute_includes rules.fetch(:description), "Path parameter"
      end
    end
  end

  def test_geocode_and_reverse_name_each_other_and_their_errors
    geocode = Lookups::Geocode::OPENAPI.fetch(:description)
    reverse = Lookups::Reverse::OPENAPI.fetch(:description)

    assert_includes geocode, "Use location_reverse when the location already has coordinates"
    assert_includes geocode, "saved location from its address"
    assert_includes geocode, "Save an address on the location first."
    assert_includes geocode, "It writes latitude and longitude only."
    assert_includes geocode, "\"Geocoding needs an address\""
    assert_includes geocode, "\"Geocoding returned no coordinates\""
    assert_includes geocode, "fails with NotFound"

    assert_includes reverse, "Use location_geocode when the location has an address"
    assert_includes reverse, "address fields of a saved location from its coordinates"
    assert_includes reverse, "Save both latitude and longitude on the location first."
    assert_includes reverse, "Existing address text stays unless force is true."
    assert_includes reverse, "Only location_geocode writes latitude and longitude."
    assert_includes reverse, "\"Reverse geocoding needs latitude and longitude\""
    assert_includes reverse, "fails with NotFound"
    assert_equal Lookups::FORCE_DESCRIPTION, Lookups::Reverse::CONTRACT.dig(:fields, :force, :description)
    assert_includes Lookups::FORCE_DESCRIPTION, "Pass true to replace address text"
    assert_includes Lookups::FORCE_DESCRIPTION, "Omit it, or pass false"
  end

  private

  def each_tool
    yield :location_geocode, Lookups::Geocode::OPENAPI, Lookups::Geocode::CONTRACT
    yield :location_reverse, Lookups::Reverse::OPENAPI, Lookups::Reverse::CONTRACT
  end

  def assert_sentence(text)
    assert_includes text, " "
    assert_match(/\.+\z/, text)
  end
end
