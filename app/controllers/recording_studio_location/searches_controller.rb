# frozen_string_literal: true

module RecordingStudioLocation
  class SearchesController < ApplicationController
    before_action :authenticate_location_request!

    def index
      results = PlaceSearch.new(adapter: RecordingStudio::Location.geocoder).candidates(
        params[:q],
        session: params[:session]
      )

      render json: {
        results: results.map { |candidate| Geocoder::Candidate.wrap(candidate).as_json },
        attribution: attribution_payload
      }
    end

    private

    def attribution_payload
      adapter = RecordingStudio::Location.geocoder
      return unless adapter.respond_to?(:attribution)

      value = adapter.attribution
      text = value.respond_to?(:text) ? value.text : value
      Geocoder::Attribution.new(text: text).as_json
    end
  end
end
