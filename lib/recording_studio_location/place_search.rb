# frozen_string_literal: true

module RecordingStudioLocation
  class PlaceSearch
    MIN_QUERY_LENGTH = 3
    CACHE_TTL = 45

    def initialize(adapter:, cache: default_cache)
      @adapter = adapter
      @cache = cache
    end

    def candidates(query, session: nil)
      normalized = query.to_s.strip
      return [] if normalized.length < MIN_QUERY_LENGTH
      return [] unless Geocoder.searchable?(@adapter)

      fetch(["search", @adapter.class.name, normalized.downcase]) do
        Array(@adapter.search(normalized, session: session))
      end
    rescue Geocoder::Error
      []
    end

    private

    def fetch(key_parts, &)
      return yield unless @cache

      @cache.fetch(key_parts, expires_in: CACHE_TTL, &)
    end

    def default_cache
      return unless defined?(Rails) && Rails.respond_to?(:cache)

      Rails.cache
    end
  end
end
