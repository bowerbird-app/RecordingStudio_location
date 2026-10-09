# frozen_string_literal: true

class LocationsController < ApplicationController
  around_action :with_demo_icon_mode, only: %i[new edit]

  def index
    @root_recording = studio_root
    @location_recordings = location_recordings(@root_recording)
  end

  def new
    @location = RecordingStudio::Location::Location.new
  end

  def create
    @location = RecordingStudio::Location::Location.new(location_params)
    if @location.valid?
      recording = studio_root!.record(RecordingStudio::Location::Location) do |location|
        location.assign_attributes(location_params)
      end
      redirect_to location_path(recording)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @recording = find_location_recording
    @location = @recording.recordable
  end

  def edit
    @recording = find_location_recording
    @location = editable_copy(@recording)
  end

  def update
    @recording = find_location_recording
    @location = editable_copy(@recording)
    @location.assign_attributes(location_params)

    if @location.valid?
      @recording = studio_root!.revise(@recording) do |location|
        location.assign_attributes(location_params)
      end
      redirect_to location_path(@recording)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def studio_workspace
    Workspace.find_by(name: "Studio Workspace")
  end

  def studio_root
    workspace = studio_workspace
    return if workspace.nil?

    RecordingStudio.root_recording_for(workspace)
  end

  def studio_root!
    workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
    RecordingStudio.root_recording_for(workspace)
  end

  def location_recordings(root)
    return RecordingStudio::Recording.none if root.nil?

    root.child_recordings.where(
      recordable_type: RecordingStudio::Location::LOCATION_TYPE,
      trashed_at: nil
    ).order(:created_at)
  end

  def find_location_recording
    location_recordings(studio_root!).find(params[:id])
  end

  def editable_copy(recording)
    copy = RecordingStudio.duplicate_recordable(recording.recordable)
    copy.assign_attributes(recording.recordable.attributes.except("id", "created_at", "updated_at"))
    copy
  end

  def location_params
    params.require(:location).permit(*RecordingStudio::Location.permitted_attributes)
  end

  def with_demo_icon_mode
    requested = params[:icon_mode].to_s.to_sym
    unless RecordingStudioLocation::Configuration::ICON_MODES.include?(requested)
      yield
      return
    end

    configuration = RecordingStudioLocation.configuration
    previous = configuration.icon_mode
    configuration.icon_mode = requested
    begin
      yield
    ensure
      configuration.icon_mode = previous
    end
  end
end
