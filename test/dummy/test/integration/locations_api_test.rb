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

  test "view is forbidden from geocode and reverse" do
    assert RecordingStudioAccessible.authorized?(actor: @viewer_client, recording: @location, role: :view)
    refute RecordingStudioAccessible.authorized?(actor: @viewer_client, recording: @location, role: :edit)

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

  test "a trashed location is not found" do
    @location.update_column(:trashed_at, Time.current)

    call(:post, "/location/geocode/#{@location.id}", @editor_token)
    assert_response :not_found, response.body

    call(:post, "/location/reverse/#{@location.id}", @editor_token)
    assert_response :not_found, response.body
  end

  test "an id of another recordable type is not found" do
    folder = record_folder(@workspace)

    call(:post, "/location/geocode/#{folder.id}", @editor_token)
    assert_response :not_found, response.body

    call(:post, "/location/reverse/#{folder.id}", @editor_token)
    assert_response :not_found, response.body
  end

  test "registry lists neither place search nor place details" do
    refute RecordingStudioApi.registered_endpoint(:location_place_search)
    refute RecordingStudioApi.registered_endpoint(:location_place_details)
    refute RecordingStudioApi.capability_action(:location_place_search)
    refute RecordingStudioApi.capability_action(:location_place_details)
    refute_includes RecordingStudioLocation::Api::ENDPOINTS, :location_place_search
    refute_includes RecordingStudioLocation::Api::ENDPOINTS, :location_place_details
    refute RecordingStudioLocation::Api::Lookups::DEFINITIONS.key?(:location_place_search)
    refute RecordingStudioLocation::Api::Lookups::DEFINITIONS.key?(:location_place_details)

    paths = RecordingStudioApi::Services::OpenapiDocument.call.fetch(:paths)
    refute paths.key?("/recording_studio_api/api/v1/location/place_search")
    refute paths.key?("/recording_studio_api/api/v1/location/place_details")
  end

  test "location api registration is two named endpoints and raises on a collision" do
    refute RecordingStudioApi.recordable_registration_for(TYPE)

    RecordingStudioLocation::Api::ENDPOINTS.each do |name|
      endpoint = RecordingStudioApi.registered_endpoint(name)
      refute_nil endpoint, name.to_s
      assert_nil RecordingStudioApi.capability_action(name)
    end

    geocode = RecordingStudioApi.registered_endpoint(:location_geocode)
    reverse = RecordingStudioApi.registered_endpoint(:location_reverse)
    assert_equal TYPE, geocode.recordable_type
    assert_equal TYPE, reverse.recordable_type
    assert_equal :edit, geocode.required_role
    assert_equal :edit, reverse.required_role
    assert geocode.scopes_recording?
    assert reverse.scopes_recording?
    assert_equal RecordingStudioLocation::Api::Lookups::Geocode, geocode.handler
    assert_equal RecordingStudioLocation::Api::Lookups::Reverse, reverse.handler
    assert_includes geocode.openapi.fetch(:description), "may cost money"
    assert_includes reverse.openapi.fetch(:description), "may cost money"
    assert_equal false, geocode.input_contract.as_json.fetch(:reject_unknown)
    assert_lookup_copy(geocode, reverse)

    paths = RecordingStudioApi::Services::OpenapiDocument.call.fetch(:paths)
    assert_equal(
      RecordingStudioLocation::Api::Lookups::RECORDING_ID_DESCRIPTION,
      path_id_description(paths, "location/geocode/{id}")
    )
    assert_equal(
      RecordingStudioLocation::Api::Lookups::RECORDING_ID_DESCRIPTION,
      path_id_description(paths, "location/reverse/{id}")
    )

    RecordingStudioLocation::Api.register!

    error = assert_raises(RecordingStudioApi::ConfigurationError) do
      RecordingStudioApi.register_endpoint(
        :location_geocode,
        http_verb: :post,
        path: "location/other_geocode/:id",
        recordable_type: TYPE,
        handler: ->(_context) { {} }
      )
    end
    assert_match(/already registered/, error.message)

    paths = RecordingStudioApi::Services::OpenapiDocument.call.fetch(:paths)
    assert paths.key?("/recording_studio_api/api/v1/location/geocode/{id}")
    assert paths.key?("/recording_studio_api/api/v1/location/reverse/{id}")
  end

  test "geocode returns the documented recording and place fields" do
    @adapter.stub_geocode(
      "12 Smith Street, Fitzroy, VIC, 3065, Australia",
      { latitude: -37.798, longitude: 144.978 }
    )

    geocoded = call(:post, "/location/geocode/#{@location.id}", @editor_token)

    assert_response :success
    assert_equal documented_response_fields, geocoded.keys
    assert_equal documented_place_fields, @location.reload.recordable.api_payload.keys.map(&:to_s)
    assert_equal @location.id.to_s, geocoded.fetch("id")
  end

  test "documented lookup errors match the response" do
    description = RecordingStudioApi.registered_endpoint(:location_geocode).openapi.fetch(:description)
    reverse_description = RecordingStudioApi.registered_endpoint(:location_reverse).openapi.fetch(:description)

    RecordingStudio::Location.geocoder = nil
    missing = call(:post, "/location/geocode/#{@location.id}", @editor_token)
    assert_response :unprocessable_entity
    assert_equal "invalid_input", missing.dig("error", "code")
    assert_equal "Assign RecordingStudio::Location.geocoder before geocoding", missing.dig("error", "message")
    assert_includes description, missing.dig("error", "message")

    RecordingStudio::Location.geocoder = @adapter
    blank = record_location(@workspace) { |location| location.title = "No address yet" }
    blank_body = call(:post, "/location/geocode/#{blank.id}", @editor_token)
    assert_response :unprocessable_entity
    assert_equal "Geocoding needs an address", blank_body.dig("error", "message")
    assert_includes description, blank_body.dig("error", "message")

    @adapter.stub_geocode(
      "12 Smith Street, Fitzroy, VIC, 3065, Australia",
      { latitude: nil, longitude: nil }
    )
    empty = call(:post, "/location/geocode/#{@location.id}", @editor_token)
    assert_response :not_found
    assert_equal "not_found", empty.dig("error", "code")
    assert_equal "Geocoding returned no coordinates", empty.dig("error", "message")
    assert_includes description, empty.dig("error", "message")

    missing_coordinates = call(:post, "/location/reverse/#{@location.id}", @editor_token)
    assert_response :unprocessable_entity
    assert_equal "Reverse geocoding needs latitude and longitude", missing_coordinates.dig("error", "message")
    assert_includes reverse_description, missing_coordinates.dig("error", "message")

    @adapter.stub_geocode(
      "12 Smith Street, Fitzroy, VIC, 3065, Australia",
      { latitude: -37.798, longitude: 144.978 }
    )
    call(:post, "/location/geocode/#{@location.id}", @editor_token)
    assert_response :success
    missed = call(:post, "/location/reverse/#{@location.id}", @editor_token)
    assert_response :not_found
    assert_equal "not_found", missed.dig("error", "code")
    assert_includes missed.dig("error", "message"), "No fake reverse result"
    assert_includes reverse_description, "fails with NotFound"
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
    root = create_workspace_root!(recordable, actor: actor)
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

  def record_folder(root, actor: @owner)
    previous = Current.actor
    Current.actor = actor
    root.record(Folder, actor:) do |folder|
      folder.name = "Cabinet"
    end
  ensure
    Current.actor = previous
  end

  def assert_lookup_copy(geocode, reverse)
    id_description = RecordingStudioLocation::Api::Lookups::RECORDING_ID_DESCRIPTION

    [geocode, reverse].each do |endpoint|
      parameter = endpoint.openapi_path_parameters.find { |entry| entry[:name] == "id" }
      assert_equal id_description, parameter.fetch(:description)
      refute_includes parameter.fetch(:description), "Path parameter"
      refute_includes endpoint.openapi.fetch(:description), "Path parameter id."
    end

    force = reverse.input_contract.as_json.dig(:fields, :force)
    assert_equal RecordingStudioLocation::Api::Lookups::FORCE_DESCRIPTION, force.fetch(:description)
  end

  def path_id_description(paths, suffix)
    operation = paths.fetch("/recording_studio_api/api/v1/#{suffix}").fetch("post")
    parameter = operation.fetch(:parameters).find { |entry| entry.fetch("name") == "id" }
    parameter.fetch("description")
  end

  def documented_response_fields
    RecordingStudioLocation::Api::Lookups::RECORDING_RESPONSE_FIELDS +
      RecordingStudioLocation::Api::Lookups::PLACE_RESPONSE_FIELDS
  end

  def documented_place_fields
    RecordingStudioLocation::Api::Lookups::PLACE_RESPONSE_FIELDS
  end

  def record_location(root, actor: @owner)
    previous = Current.actor
    Current.actor = actor
    root.record(RecordingStudio::Location::Location, actor:) do |location|
      if block_given?
        yield location
      else
        location.title = "Office HQ"
        location.location_type = "office"
        location.address_line_1 = "12 Smith Street"
        location.locality = "Fitzroy"
        location.region = "VIC"
        location.postal_code = "3065"
        location.country_code = "AU"
      end
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
