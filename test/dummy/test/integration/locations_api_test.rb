# frozen_string_literal: true

require "test_helper"

class LocationsApiTest < ActionDispatch::IntegrationTest
  BASE = "/recording_studio_api/api/v1"
  TYPE = "RecordingStudio::Location::Location"

  setup do
    @previous_actor = Current.actor
    @previous_geocoder = RecordingStudio::Location.geocoder
    @owner = user("owner")
    @editor = user("editor")
    @viewer = user("viewer")
    Current.actor = @owner
    @workspace = owned_root(Workspace.create!(name: "API Places #{SecureRandom.hex(4)}"))
    @stranger = user("stranger")
    @other = owned_root(Workspace.create!(name: "Other places #{SecureRandom.hex(4)}"), actor: @stranger)
    @editor_access = grant!(@workspace, @editor, :edit)
    @viewer_access = grant!(@workspace, @viewer, :view)
    @editor_token, = token_for(@editor_access)
    @viewer_token, = token_for(@viewer_access)
    @adapter = RecordingStudioLocation::Geocoder::Fake.demo
    RecordingStudio::Location.geocoder = @adapter
    @location = record_location(@workspace)
  end

  teardown do
    Current.actor = @previous_actor
    RecordingStudio::Location.geocoder = @previous_geocoder
  end

  test "place search and details succeed through the endpoint and capability action" do
    searched = call(:get, "/location/place_search", @editor_token, query: "melbourne")
    assert_response :success, response.body
    assert searched.fetch("results").any? { |result| result["id"] == "demo-mcec" }
    refute_includes response.body, "api_key"

    detailed = call(:get, "/location/place_details", @editor_token, place_id: "demo-mcec", lookup: "full")
    assert_response :success, response.body
    assert_equal "Melbourne Convention and Exhibition Centre", detailed.fetch("name")
    assert_equal "South Wharf", detailed.fetch("locality")

    member_search = call(
      :get,
      "/locations/#{@location.id}/actions/place_search",
      @editor_token,
      query: "melbourne"
    )
    assert_response :success, response.body
    assert_equal searched.fetch("results"), member_search.fetch("results")

    member_details = call(
      :get,
      "/locations/#{@location.id}/actions/place_details",
      @editor_token,
      place_id: "demo-mcec"
    )
    assert_response :success, response.body
    assert_equal detailed.fetch("name"), member_details.fetch("name")
  end

  test "geocode and reverse revise the location through the adapter seam" do
    @adapter.stub_geocode(
      "12 Smith Street, Fitzroy, VIC, 3065, Australia",
      {
        latitude: -37.798,
        longitude: 144.978,
        locality: "should not apply"
      }
    )
    @adapter.stub_reverse(
      -37.798,
      144.978,
      {
        address_line_1: "12 Smith Street",
        locality: "Fitzroy",
        region: "VIC",
        postal_code: "3065",
        country_code: "AU"
      }
    )

    geocoded = call(:post, "/locations/#{@location.id}/actions/geocode", @editor_token)
    assert_response :success, response.body
    assert_equal @location.id, geocoded.fetch("id")
    assert_in_delta(-37.798, geocoded.fetch("latitude").to_f)
    assert_in_delta 144.978, geocoded.fetch("longitude").to_f
    assert_equal "Fitzroy", geocoded.fetch("locality")
    previous_recordable_id = @location.recordable_id
    @location.reload
    refute_equal previous_recordable_id, @location.recordable_id
    assert_in_delta(-37.798, @location.recordable.latitude)

    reversed = call(:post, "/locations/#{@location.id}/reverse", @editor_token)
    assert_response :success, response.body
    assert_equal @location.id, reversed.fetch("id")
    @location.reload
    assert_equal "12 Smith Street", @location.recordable.address_line_1
  end

  test "view can search and is forbidden from geocode" do
    call(:get, "/location/place_search", @viewer_token, query: "melbourne")
    assert_response :success, response.body

    call(:get, "/locations/#{@location.id}/actions/place_details", @viewer_token, place_id: "demo-mcec")
    assert_response :success, response.body

    call(:post, "/locations/#{@location.id}/actions/geocode", @viewer_token)
    assert_response :forbidden, response.body

    call(:post, "/locations/#{@location.id}/actions/reverse", @viewer_token)
    assert_response :forbidden, response.body
  end

  test "a location in another workspace is not found" do
    stranger_location = record_location(@other, actor: @stranger)

    call(:get, "/locations/#{stranger_location.id}/actions/place_search", @editor_token, query: "melbourne")
    assert_response :not_found, response.body

    call(:post, "/locations/#{stranger_location.id}/actions/geocode", @editor_token)
    assert_response :not_found, response.body

    call(:post, "/locations/#{stranger_location.id}/geocode", @editor_token)
    assert_response :not_found, response.body
  end

  test "missing search and details fields are unprocessable" do
    call(:get, "/location/place_search", @editor_token)
    assert_response :unprocessable_entity, response.body

    call(:get, "/location/place_details", @editor_token, place_id: "")
    assert_response :unprocessable_entity, response.body

    call(:get, "/location/place_details", @editor_token, place_id: "demo-mcec", lookup: "satellite")
    assert_response :unprocessable_entity, response.body
  end

  test "location api registration skips crud and documents lookup actions" do
    registration = RecordingStudioApi.recordable_registration_for(TYPE)
    assert_equal %w[geocode place_details place_search reverse].sort, registration.capability_actions.sort
    assert_equal false, registration.auto_capability_actions
    RecordingStudioLocation::Api::Crud::OPERATIONS.each do |action|
      assert_equal RecordingStudioLocation::Api::Crud::Reject, RecordingStudioApi.resource_handler(TYPE, action)
    end

    call(:get, "/locations", @editor_token)
    assert_response :unprocessable_entity, response.body
    call(:get, "/locations/#{@location.id}", @editor_token)
    assert_response :unprocessable_entity, response.body
    call(:post, "/locations", @editor_token, parent_id: @workspace.id, title: "Nope")
    assert_response :unprocessable_entity, response.body

    search = RecordingStudioApi.capability_action(:place_search)
    details = RecordingStudioApi.capability_action(:place_details)
    geocode = RecordingStudioApi.capability_action(:geocode)
    reverse = RecordingStudioApi.capability_action(:reverse)
    assert_equal :view, search.required_role
    assert_equal :view, details.required_role
    assert_equal :edit, geocode.required_role
    assert_equal :edit, reverse.required_role
    assert_equal :location_lookup, search.capability
    assert_equal "Location - Search Places", search.openapi.fetch(:title)
    assert_equal false, search.input_contract.as_json.fetch(:reject_unknown)
    assert_equal RecordingStudioLocation::Api::Lookups::PlaceSearch,
                 RecordingStudioApi.registered_endpoint(:place_search).handler
  end

  private

  def user(name)
    User.create!(
      email: "#{name}-#{SecureRandom.hex(4)}@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    )
  end

  def owned_root(recordable, actor: @owner)
    root = RecordingStudio.root_recording_for(recordable)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: root, actor:)
    raise result.error if result.failure?

    root
  end

  def grant!(recording, actor, role)
    result = RecordingStudioAccessible.grant_access(recording:, actor:, role:, manager_actor: @owner)
    raise result.error if result.failure?

    result.value
  end

  def token_for(access_recording)
    provision = RecordingStudioApi::Services::ProvisionApiClient.call(
      access_point_recording: access_recording.parent_recording || access_recording.root_recording,
      manager_actor: @owner,
      role: access_recording.recordable.role,
      name: "Client #{SecureRandom.hex(3)}"
    )
    raise provision.error unless provision.success?

    issued = RecordingStudioApi::Services::IssueOauthAccessToken.call(
      grant_type: "client_credentials",
      client_id: provision.value.fetch(:credential).oauth_client_id,
      client_secret: provision.value.fetch(:token)
    )
    raise issued.error unless issued.success?

    [issued.value.fetch(:access_token), provision.value.fetch(:api_client)]
  end

  def record_location(root, actor: @owner)
    previous = Current.actor
    Current.actor = actor
    root.record(RecordingStudio::Location::Location, actor:) do |location|
      location.title = "Office HQ"
      location.location_type = "office"
      location.address_line_1 = "12 Smith Street"
      location.locality = "Fitzroy"
      location.region = "VIC"
      location.postal_code = "3065"
      location.country_code = "AU"
    end
  ensure
    Current.actor = previous
  end

  def call(method, path, token, params = {})
    send(method, "#{BASE}#{path}", params:, headers: {
      "Authorization" => "Bearer #{token}",
      "Accept" => "application/json"
    }, as: :json)
    response.media_type.to_s.include?("json") ? JSON.parse(response.body) : {}
  rescue JSON::ParserError
    {}
  end
end
