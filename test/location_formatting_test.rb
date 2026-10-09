# frozen_string_literal: true

require "test_helper"

class LocationFormattingTest < Minitest::Test
  Place = Struct.new(
    :title,
    :name,
    :address_line_1,
    :address_line_2,
    :locality,
    :region,
    :postal_code,
    :country_code,
    :latitude,
    :longitude,
    keyword_init: true
  ) do
    include RecordingStudio::Location::Formatting
  end

  def test_display_name_uses_a_place_name_when_one_is_present
    place = Place.new(name: "Melbourne Convention Centre", locality: "Melbourne", country_code: "AU")

    assert_equal "Melbourne Convention Centre", place.display_name
  end

  def test_display_name_prefers_a_user_title_over_the_venue_name
    place = Place.new(title: "Office HQ", name: "Melbourne Convention Centre", locality: "Melbourne")

    assert_equal "Office HQ", place.display_name
  end

  def test_display_name_joins_locality_region_and_country_and_skips_blanks
    fitzroy = Place.new(locality: "Fitzroy", region: "Victoria", country_code: "AU")
    melbourne = Place.new(locality: " Melbourne ", region: " ", country_code: "au")
    blank = Place.new(locality: "", region: nil, country_code: "AU")

    assert_equal "Fitzroy, Victoria, Australia", fitzroy.display_name
    assert_equal "Melbourne, Australia", melbourne.display_name
    assert_equal "Australia", blank.display_name
    refute_includes fitzroy.display_name, ", ,"
    refute_includes melbourne.display_name, ", ,"
  end

  def test_full_address_omits_blank_segments
    place = Place.new(
      address_line_1: "12 Smith Street",
      address_line_2: " ",
      locality: "Fitzroy",
      region: "VIC",
      postal_code: "3065",
      country_code: "AU"
    )
    country_only = Place.new(address_line_1: "", locality: nil, country_code: "AU")

    assert_equal "12 Smith Street, Fitzroy VIC 3065, Australia", place.full_address
    assert_equal "Australia", country_only.full_address
    refute_includes place.full_address, ", ,"
    refute_includes country_only.full_address, ", ,"
  end

  def test_coordinates_require_both_values
    both = Place.new(latitude: BigDecimal("-37.798"), longitude: BigDecimal("144.978"))
    latitude_only = Place.new(latitude: -37.798, longitude: nil)
    longitude_only = Place.new(latitude: nil, longitude: 144.978)
    blank = Place.new(latitude: nil, longitude: nil)
    zeros = Place.new(latitude: 0, longitude: 0)

    assert_in_delta(-37.798, both.coordinates[0])
    assert_in_delta 144.978, both.coordinates[1]
    assert_nil latitude_only.coordinates
    assert_nil longitude_only.coordinates
    assert_nil blank.coordinates
    assert_equal [0.0, 0.0], zeros.coordinates
  end

  def test_display_name_can_fall_back_to_coordinates
    place = Place.new(latitude: -37.798, longitude: 144.978)

    assert_equal "-37.798, 144.978", place.display_name
    assert_equal "", place.full_address
  end

  def test_unknown_country_code_is_shown_as_entered
    place = Place.new(locality: "Somewhere", country_code: "ZZ")

    assert_equal "Somewhere, ZZ", place.display_name
  end
end
