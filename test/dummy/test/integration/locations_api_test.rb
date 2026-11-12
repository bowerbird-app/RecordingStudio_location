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
    @editor_access = grant!(@workspace, @editor, :edit)
    @viewer_access = grant!(@workspace, @viewer, :view)
    @editor_token, @editor_client = token_for(@editor_access)
    @viewer_token, @viewer_client = token_for(@viewer_access)
    @stranger = user("stranger")
    previous = Current.actor
    Current.actor = @stranger
    @other = owned_root(Workspace.create!(name: "Other places #{SecureRandom.hex(4)}"), actor: @stranger)
    Current.actor = previous
    @adapter = RecordingStudioLocation::Geocoder::Fake.demo
    RecordingStudio::Location.geocoder = @adapter
    @location = record_location(@workspace)
  end

  teardown do
    Current.actor = @previous_actor
    RecordingStudio::Location.geocoder = @previous_geocoder
  end

  test "place search and details succeed through the named endpoints" do
    searched = call(:get, "/location/place_search", @editor_token, query: "melbourne")
    assert_response :success, response.body
    assert searched.fetch("results").any? { |result| result["id"] == "demo-mcec" }
    refute_includes response.body, "api_key"

    detailed = call(:get, "/location/place_details", @editor_token, place_id: "demo-mcec", lookup: "full")
    assert_response :success, response.body
    assert_equal "Melbourne Convention and Exhibition Centre", detailed.fetch("name")
    assert_equal "South Wharf", detailed.fetch("locality")
  end

  test "geocode and reverse revise the location through an edit Access grant" do
    assert RecordingStudioAccessible.authorized?(actor: @editor_client, recording: @location, role: :edit)

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

    geocoded = call(:post, "/location/geocode/#{@location.id}", @editor_token)
    assert_response :success, response.body
    assert_equal @location.id, geocoded.fetch("id")
    assert_in_delta(-37.798, geocoded.fetch("latitude").to_f)
    assert_in_delta 144.978, geocoded.fetch("longitude").to_f
    assert_equal "Fitzroy", geocoded.fetch("locality")
    previous_recordable_id = @location.recordable_id
    @location.reload
    refute_equal previous_recordable_id, @location.recordable_id
    assert_in_delta(-37.798, @location.recordable.latitude)

    reversed = call(:post, "/location/reverse/#{@location.id}", @editor_token)
    assert_response :success, response.body
    assert_equal @location.id, reversed.fetch("id")
    @location.reload
    assert_equal "12 Smith Street", @location.recordable.address_line_1
  end

  test "view can search and is forbidden from geocode and reverse" do
    assert RecordingStudioAccessible.authorized?(actor: @viewer_client, recording: @location, role: :view)
    refute RecordingStudioAccessible.authorized?(actor: @viewer_client, recording: @location, role: :edit)

    call(:get, "/location/place_search", @viewer_token, query: "melbourne")
    assert_response :success, response.body

    call(:get, "/location/place_details", @viewer_token, place_id: "demo-mcec")
    assert_response :success, response.body

    call(:post, "/location/geocode/#{@location.id}", @viewer_token)
    assert_response :forbidden, response.body

    call(:post, "/location/reverse/#{@location.id}", @viewer_token)
    assert_response :forbidden, response.body
  end

  test "a location in another workspace is not found" do
    stranger_location = record_location(@other, actor: @stranger)

    call(:post, "/location/geocode/#{stranger_location.id}", @editor_token)
    assert_response :not_found, response.body

    call(:post, "/location/reverse/#{stranger_location.id}", @editor_token)
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

  test "location api registration is four named endpoints and raises on a collision" do
    refute RecordingStudioApi.recordable_registration_for(TYPE)

    RecordingStudioLocation::Api::ENDPOINTS.each do |name|
      endpoint = RecordingStudioApi.registered_endpoint(name)
      refute_nil endpoint, name.to_s
      assert_nil RecordingStudioApi.capability_action(name)
    end

    search = RecordingStudioApi.registered_endpoint(:location_place_search)
    details = RecordingStudioApi.registered_endpoint(:location_place_details)
    geocode = RecordingStudioApi.registered_endpoint(:location_geocode)
    reverse = RecordingStudioApi.registered_endpoint(:location_reverse)
    assert_equal :view, RecordingStudioLocation::Api::Lookups.definition(:location_place_search).fetch(:required_role)
    assert_equal :view, RecordingStudioLocation::Api::Lookups.definition(:location_place_details).fetch(:required_role)
    assert_equal :edit, RecordingStudioLocation::Api::Lookups.definition(:location_geocode).fetch(:required_role)
    assert_equal :edit, RecordingStudioLocation::Api::Lookups.definition(:location_reverse).fetch(:required_role)
    assert_equal RecordingStudioLocation::Api::Lookups::PlaceSearch, search.handler
    assert_equal RecordingStudioLocation::Api::Lookups::PlaceDetails, details.handler
    assert_equal RecordingStudioLocation::Api::Lookups::Geocode, geocode.handler
    assert_equal RecordingStudioLocation::Api::Lookups::Reverse, reverse.handler
    assert_includes search.openapi.fetch(:description), "paid traffic"
    assert_includes details.openapi.fetch(:description), "paid traffic"
    assert_includes geocode.openapi.fetch(:description), "paid traffic"
    assert_includes reverse.openapi.fetch(:description), "paid traffic"
    assert_equal false, search.input_contract.as_json.fetch(:reject_unknown)

    RecordingStudioLocation::Api.register!

    error = assert_raises(RecordingStudioApi::ConfigurationError) do
      RecordingStudioApi.register_endpoint(
        :location_place_search,
        http_verb: :get,
        path: "location/other_search",
        handler: ->(_context) { {} }
      )
    end
    assert_match(/already registered/, error.message)

    paths = RecordingStudioApi::Services::OpenapiDocument.call.fetch(:paths)
    assert paths.key?("/recording_studio_api/api/v1/location/place_search")
    assert paths.key?("/recording_studio_api/api/v1/location/place_details")
    assert paths.key?("/recording_studio_api/api/v1/location/geocode/{id}")
    assert paths.key?("/recording_studio_api/api/v1/location/reverse/{id}")
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
    access_point = access_recording.parent_recording || access_recording.root_recording
    wanted_role = access_recording.recordable.role
    provision = RecordingStudioApi::Services::ProvisionApiClient.call(
      access_point_recording: access_point,
      manager_actor: @owner,
      role: :edit,
      name: "Client #{SecureRandom.hex(3)}"
    )
    raise provision.error unless provision.success?

    client = provision.value.fetch(:api_client)
    issued = RecordingStudioApi::Services::IssueOauthAccessToken.call(
      grant_type: "client_credentials",
      client_id: provision.value.fetch(:credential).oauth_client_id,
      client_secret: provision.value.fetch(:token)
    )
    raise issued.error unless issued.success?

    if wanted_role.to_s != "edit"
      grant = RecordingStudioAccessible.grant_access(
        recording: access_point,
        actor: client,
        role: wanted_role,
        manager_actor: @owner
      )
      raise grant.error if grant.failure?
    end

    [ issued.value.fetch(:access_token), client ]
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
