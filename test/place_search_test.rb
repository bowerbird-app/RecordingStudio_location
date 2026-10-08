# frozen_string_literal: true

require "test_helper"
require "active_support/cache"

class PlaceSearchTest < Minitest::Test
  def setup
    @fake = RecordingStudioLocation::Geocoder::Fake.new
    @fake.stub_search("mel", [{ id: "1", label: "Melbourne", name: "Melbourne" }])
    @cache = ActiveSupport::Cache::MemoryStore.new
    @search = RecordingStudioLocation::PlaceSearch.new(adapter: @fake, cache: @cache)
  end

  def test_rejects_short_queries_without_calling_the_adapter
    assert_equal [], @search.candidates("me")
    assert_equal [], @fake.search_calls
  end

  def test_returns_candidates_and_caches_them
    first = @search.candidates("melbourne")
    second = @search.candidates("melbourne")

    assert_equal "1", first.first.id
    assert_equal first.first.id, second.first.id
    assert_equal ["melbourne"], @fake.search_calls
  end

  def test_missing_adapter_or_errors_return_empty
    empty = RecordingStudioLocation::PlaceSearch.new(adapter: nil, cache: @cache)
    assert_equal [], empty.candidates("melbourne")

    failing = Class.new(RecordingStudioLocation::Geocoder::Adapter) do
      def capabilities
        { search: true, details: false, lookup_depths: [] }
      end

      def search(*)
        raise RecordingStudioLocation::Geocoder::RequestError, "nope key=secret"
      end
    end.new

    results = RecordingStudioLocation::PlaceSearch.new(adapter: failing, cache: @cache).candidates("melbourne")
    assert_equal [], results
  end
end
