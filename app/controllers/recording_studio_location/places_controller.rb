# frozen_string_literal: true

module RecordingStudioLocation
  class PlacesController < ApplicationController
    before_action :authenticate_location_request!

    def show
      render json: Geocoder::Result.wrap(place_result).as_json
    rescue Geocoder::Missing, Geocoder::QueryError, Geocoder::NotFound
      render json: { error: "not_found" }, status: :not_found
    rescue Geocoder::RequestError
      render json: { error: "unavailable" }, status: :bad_gateway
    end

    private

    def place_result
      PlaceLookup.new(adapter: RecordingStudio::Location.geocoder).result(
        params[:id],
        depth: params[:lookup].presence || RecordingStudioLocation.configuration.lookup_depth,
        session: params[:session]
      )
    end
  end
end
