# frozen_string_literal: true

class AddTitleTypeAndIconToRecordingStudioLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :recording_studio_locations, :title, :string
    add_column :recording_studio_locations, :location_type, :string
    add_column :recording_studio_locations, :icon, :string
  end
end
