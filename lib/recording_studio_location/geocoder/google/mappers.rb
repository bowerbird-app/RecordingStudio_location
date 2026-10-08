# frozen_string_literal: true

module RecordingStudioLocation
  module Geocoder
    class Google
      class GeocodeMapper
        def initialize(payload)
          @payload = payload
          @place = Array(payload["results"]).first
        end

        def result
          raise NotFound, "Geocoding returned no results" if @place.nil?

          Result.new(**mapped_attributes)
        end

        private

        def mapped_attributes
          geometry.merge(AddressComponents.new(@place["address_components"]).to_h).merge(
            formatted_address: @place["formatted_address"],
            raw: @payload
          )
        end

        def geometry
          location = @place.dig("geometry", "location") || {}
          { latitude: location["lat"], longitude: location["lng"] }
        end
      end

      class AutocompleteMapper
        def initialize(payload)
          @payload = payload
        end

        def candidates
          Array(@payload["predictions"]).filter_map { |prediction| candidate_for(prediction) }
        end

        private

        def candidate_for(prediction)
          label = prediction["description"].to_s.strip
          id = prediction["place_id"].to_s.strip
          return if label.empty? || id.empty?

          Candidate.new(
            id: id,
            label: label,
            name: prediction.dig("structured_formatting", "main_text"),
            raw: prediction
          )
        end
      end

      class DetailsMapper
        def initialize(payload)
          @payload = payload
          @place = payload["result"]
        end

        def result
          raise NotFound, "Place lookup returned no results" if @place.nil?

          Result.new(**mapped_attributes)
        end

        private

        def mapped_attributes
          geometry.merge(AddressComponents.new(@place["address_components"]).to_h).merge(
            name: @place["name"].to_s.strip.presence,
            formatted_address: @place["formatted_address"],
            raw: @payload
          )
        end

        def geometry
          location = @place.dig("geometry", "location") || {}
          { latitude: location["lat"], longitude: location["lng"] }
        end
      end
    end
  end
end
