# frozen_string_literal: true

require "test_helper"

class MapGoogleTest < Minitest::Test
  def test_preview_builds_an_embed_url_with_the_browser_key
    adapter = RecordingStudioLocation::Map::Google.new(browser_api_key: "browser-key")
    preview = adapter.preview(latitude: -37.8253, longitude: 144.952)

    assert_includes preview.url, "https://www.google.com/maps/embed/v1/place"
    assert_includes preview.url, "key=browser-key"
    assert_includes preview.url, "q=-37.825300,144.952000"
    assert_includes preview.url_template, "{lat},{lng}"
    assert preview.visible?
  end

  def test_blank_browser_key_raises_before_building_a_url
    error = assert_raises(ArgumentError) do
      RecordingStudioLocation::Map::Google.new(browser_api_key: "  ")
    end

    assert_includes error.message, "browser_api_key"
  end

  def test_invalid_coordinates_leave_the_iframe_url_blank
    adapter = RecordingStudioLocation::Map::Google.new(browser_api_key: "browser-key")
    preview = adapter.preview(latitude: -37.8, longitude: nil)

    refute preview.visible?
    assert_nil preview.url
    assert_includes preview.url_template, "browser-key"
  end
end
