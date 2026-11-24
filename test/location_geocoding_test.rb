# frozen_string_literal: true

require "test_helper"

class LocationGeocodingTest < Minitest::Test
  class Place
    include RecordingStudio::Location::Geocoding

    attr_accessor :address_line_1, :address_line_2, :locality, :region,
                  :postal_code, :country_code, :latitude, :longitude

    def initialize(**attributes)
      attributes.each { |name, value| public_send(:"#{name}=", value) }
    end
  end

  def setup
    @previous = RecordingStudio::Location.geocoder
    @fake = RecordingStudioLocation::Geocoder::Fake.new
    RecordingStudio::Location.geocoder = @fake
  end

  def teardown
    RecordingStudio::Location.geocoder = @previous
  end

  def test_geocode_bang_sets_coordinates_only
    @fake.stub_geocode(
      "12 Smith Street, Fitzroy, Australia",
      latitude: -37.798,
      longitude: 144.978,
      address_line_1: "ignored",
      locality: "ignored"
    )
    place = Place.new(address_line_1: "12 Smith Street", locality: "Fitzroy", country_code: "AU")

    place.geocode!

    assert_in_delta(-37.798, place.latitude)
    assert_in_delta 144.978, place.longitude
    assert_equal "12 Smith Street", place.address_line_1
    assert_equal "Fitzroy", place.locality
  end

  def test_reverse_bang_fills_blanks_and_force_overwrites
    @fake.stub_reverse(
      -37.798,
      144.978,
      address_line_1: "12 Smith Street",
      locality: "Fitzroy",
      region: "VIC",
      country_code: "AU"
    )
    place = Place.new(locality: "Melbourne", latitude: -37.798, longitude: 144.978)

    place.reverse!

    assert_equal "Melbourne", place.locality
    assert_equal "12 Smith Street", place.address_line_1
    assert_equal "VIC", place.region

    place.reverse!(force: true)

    assert_equal "Fitzroy", place.locality
  end

  def test_reverse_bang_leaves_an_unknown_country_code_blank
    @fake.stub_reverse(1.0, 2.0, locality: "Pristina", country_code: "ZZ")
    place = Place.new(latitude: 1.0, longitude: 2.0)

    place.reverse!

    assert_nil place.country_code
    assert_equal "Pristina", place.locality

    @fake.stub_reverse(3.0, 4.0, country_code: "xk")
    listed = Place.new(country_code: "AU", latitude: 3.0, longitude: 4.0)

    listed.reverse!(force: true)

    assert_equal "XK", listed.country_code
  end

  def test_geocode_bang_raises_for_missing_adapter_blank_query_and_missing_coordinates
    place = Place.new(locality: "Melbourne", country_code: "AU")
    RecordingStudio::Location.geocoder = nil

    assert_raises(RecordingStudioLocation::Geocoder::Missing) { place.geocode! }

    RecordingStudio::Location.geocoder = @fake
    assert_raises(RecordingStudioLocation::Geocoder::QueryError) { Place.new.geocode! }
    assert_raises(RecordingStudioLocation::Geocoder::QueryError) { Place.new.reverse! }

    @fake.stub_geocode("Melbourne, Australia", locality: "Melbourne")
    assert_raises(RecordingStudioLocation::Geocoder::NotFound) { place.geocode! }
  end
end
