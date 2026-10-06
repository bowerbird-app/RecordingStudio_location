# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    workspace = Workspace.find_by(name: "Studio Workspace")
    @root_recording = workspace && RecordingStudio.root_recording_for(workspace)
    @location_recording = if @root_recording
      @root_recording.child_recordings.where(
        recordable_type: RecordingStudio::Location::LOCATION_TYPE,
        trashed_at: nil
      ).order(:created_at).first
    end
  end
end
