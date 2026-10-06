# frozen_string_literal: true

class CreateRecordingStudioLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :recording_studio_locations, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name
      t.string :address_line_1
      t.string :address_line_2
      t.string :locality
      t.string :region
      t.string :postal_code
      t.string :country_code, limit: 2
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 11, scale: 7

      t.timestamps
    end

    add_index :recording_studio_locations, :country_code
    add_index :recording_studio_locations, :locality
    add_index :recording_studio_locations, :name
  end
end