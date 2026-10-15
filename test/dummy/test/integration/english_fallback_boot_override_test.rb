# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

# Boot-loaded host English override for a rarely shown map title template
# (Stimulus data attribute only) wins on the real new-location page. Fixture:
# test/dummy/config/locales/recording_studio_location_host.en.yml
# Does not rewrite existing HostNestedLocaleOverrideTest assertions.
class EnglishFallbackBootOverrideTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  HOST_OVERRIDE_LOCALE = Rails.root.join("config/locales/recording_studio_location_host.en.yml").to_s.freeze
  KEY = "recording_studio.location.map.title_with_coordinates"
  HOST = "HOST map %{latitude}, %{longitude}"
  GEM_ENGLISH = "Map of %{latitude}, %{longitude}"

  setup do
    @user = User.find_or_create_by!(email: "english-fallback-boot@example.com") do |user|
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
    end
    sign_in @user
    @workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
    RecordingStudio.root_recording_for(@workspace)

    # Force I18n to initialize before store_translations / assertions.
    I18n.t("recording_studio.location.fields.title")
  end

  test "boot-loaded host english override wins on new location map title template" do
    assert_boot_loaded_override_preconditions!

    get new_location_path

    assert_response :success
    assert_select "h1", text: "New location"
    assert_select "[data-recording-studio-location--place-search-map-title-template-value=?]", HOST
    assert_equal HOST, I18n.t(KEY)
    assert_equal HOST, RecordingStudio.t(KEY)
    assert_equal HOST, RecordingStudioLocation::Copy.t("map.title_with_coordinates")
    refute_equal GEM_ENGLISH, RecordingStudioLocation::Copy.t("map.title_with_coordinates")
  end

  test "engine boot registered location en.yml without this test calling the initializer" do
    expected = File.expand_path(RecordingStudioLocation::Engine.root.join("config/locales/en.yml"))
    paths = RecordingStudio::Translation.send(:registered_shipped_english_paths)

    assert_includes paths, expected,
                    "removing recording_studio_location.register_shipped_english must fail this test"
    assert_equal "Title",
                 RecordingStudio::Translation.shipped_english.fetch(
                   "recording_studio.location.fields.title"
                 )
  end

  private

  def assert_boot_loaded_override_preconditions!
    assert File.exist?(HOST_OVERRIDE_LOCALE), "expected boot-loaded host override at #{HOST_OVERRIDE_LOCALE}"
    assert_includes File.expand_path(HOST_OVERRIDE_LOCALE), "/config/locales/"

    load_path = I18n.load_path.map { |path| File.expand_path(path) }
    gem_en = File.expand_path(RecordingStudioLocation::Engine.root.join("config/locales/en.yml"))
    host_en = File.expand_path(HOST_OVERRIDE_LOCALE)

    assert_includes load_path, gem_en
    assert_includes load_path, host_en
    assert_operator load_path.index(gem_en), :<, load_path.index(host_en),
                    "gem en.yml must load before host boot override"

    original_load_path = I18n.load_path.dup
    assert_equal HOST, I18n.t(KEY), "I18n.t must return HOST before the page render"
    assert_equal original_load_path, I18n.load_path, "load_path must stay untouched"
    refute_equal GEM_ENGLISH, I18n.t(KEY)
  end
end
