# frozen_string_literal: true

module RecordingStudioLocation
  module Geocoder
    class Fake
      module Demo
        SEARCHES = {
          "mel" => [
            {
              id: "demo-mcec",
              label: "Melbourne Convention and Exhibition Centre, South Wharf VIC, Australia",
              name: "Melbourne Convention and Exhibition Centre"
            },
            {
              id: "demo-federation-square",
              label: "Federation Square, Melbourne VIC, Australia",
              name: "Federation Square"
            }
          ],
          "fitzroy" => [
            {
              id: "demo-fitzroy",
              label: "Fitzroy, VIC, Australia",
              name: "Fitzroy"
            }
          ]
        }.freeze

        DETAILS = {
          "demo-mcec" => {
            name: "Melbourne Convention and Exhibition Centre",
            address_line_1: "1 Convention Centre Place",
            locality: "South Wharf",
            region: "VIC",
            postal_code: "3006",
            country_code: "AU",
            latitude: -37.8253,
            longitude: 144.9520,
            formatted_address: "1 Convention Centre Place, South Wharf VIC 3006, Australia"
          },
          "demo-federation-square" => {
            name: "Federation Square",
            address_line_1: "Swanston Street",
            locality: "Melbourne",
            region: "VIC",
            postal_code: "3000",
            country_code: "AU",
            latitude: -37.8179,
            longitude: 144.9691,
            formatted_address: "Federation Square, Melbourne VIC 3000, Australia"
          },
          "demo-fitzroy" => {
            name: "Fitzroy",
            locality: "Fitzroy",
            region: "VIC",
            postal_code: "3065",
            country_code: "AU",
            latitude: -37.798,
            longitude: 144.978,
            formatted_address: "Fitzroy VIC 3065, Australia"
          }
        }.freeze

        def self.seed(fake)
          SEARCHES.each { |query, candidates| fake.stub_search(query, candidates) }
          DETAILS.each { |id, result| fake.stub_details(id, result) }
          fake
        end
      end
    end
  end
end
