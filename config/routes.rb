# frozen_string_literal: true

RecordingStudioLocation::Engine.routes.draw do
  root "home#index"
  get "searches", to: "searches#index", as: :searches
  get "places", to: "places#show", as: :places
end
