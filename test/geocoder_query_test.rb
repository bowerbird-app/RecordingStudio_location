# frozen_string_literal: true

require "test_helper"

class GeocoderQueryTest < Minitest::Test
  Place = Struct.new(
    :address_line_1,
    :address_line_2,
    :locality,
    :region,
    :postal_code,
    :country_code,
    keyword_init: true
  )

  def test_joins_location_fields_and_country_name
    place = Place.new(
      address_line_1: "12 Smith Street",
      address_line_2: " ",
      locality: "Fitzroy",
      region: "VIC",
      postal_code: "3065",
      country_code: "au"
    )

    assert_equal(
      "12 Smith Street, Fitzroy, VIC, 3065, Australia",
      RecordingStudioLocation::Geocoder::Query.from(place)
    )
  end

  def test_string_query_is_stripped
    assert_equal "Melbourne", RecordingStudioLocation::Geocoder::Query.from("  Melbourne  ")
    assert_equal "", RecordingStudioLocation::Geocoder::Query.from("   ")
  end
end
