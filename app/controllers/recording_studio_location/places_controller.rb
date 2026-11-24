# frozen_string_literal: true

module RecordingStudioLocation
  class PlacesController < ApplicationController
    before_action :authenticate_location_request!

    def show
      render json: place_details
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

    def place_details
      payload = Geocoder::Result.wrap(place_result).as_json
      code = RecordingStudio::Location::Countries.country_code_on_list(payload["country_code"])
      payload.merge("country_code" => code)
    end
  end
end
