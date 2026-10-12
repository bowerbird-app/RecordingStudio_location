# frozen_string_literal: true

require "test_helper"

class LocationValidationI18nTest < ActiveSupport::TestCase
  setup do
    @previous_backend = I18n.backend
    @previous_load_path = I18n.load_path.dup
    @previous_locale = I18n.locale
    @previous_available = I18n.available_locales.dup
    @previous_config = snapshot_configuration
    I18n.locale = :en
  end

  teardown do
    restore_configuration(@previous_config)
    I18n.load_path = @previous_load_path
    I18n.backend = @previous_backend
    I18n.locale = @previous_locale
    I18n.available_locales = @previous_available
    assert_equal @previous_load_path, I18n.load_path,
                 "validation i18n tests must not mutate I18n.load_path"
  end

  test "english inclusion and format details keep main symbol types" do
    RecordingStudioLocation.configuration.icon_mode = :choose
    location = RecordingStudio::Location::Location.new(
      location_type: "warehouse",
      icon: "sparkles",
      country_code: "Australia"
    )

    refute location.valid?

    assert_equal [{ error: :inclusion, value: "warehouse" }], location.errors.details[:location_type]
    assert_equal [{ error: :inclusion, value: "sparkles" }], location.errors.details[:icon]
    # normalize_country_code upcased before validation (same as main).
    assert_equal [{ error: :invalid, value: "AUSTRALIA" }], location.errors.details[:country_code]
    assert_includes location.errors[:location_type], "is not in the list of types"
    assert_includes location.errors[:icon], "is not in the list of icons"
    assert_includes location.errors[:country_code], "must be a two-letter ISO country code"
  end

  test "english string-typed coordinate error details match main" do
    location = RecordingStudio::Location::Location.new(longitude: "north")

    refute location.valid?

    # Main runs numericality (:not_a_number) and the custom String-typed check.
    assert_includes location.errors.details[:longitude], { error: :not_a_number, value: "north" }
    assert_includes location.errors.details[:longitude], { error: "must be a number" }
    assert_includes location.errors[:longitude], "must be a number"
    assert location.errors.added?(:longitude, "must be a number")
  end

  test "french full_messages use translated validation copy" do
    I18n.available_locales = Array(I18n.available_locales) | %i[en fr]
    I18n.backend.store_translations(
      :fr,
      {
        recording_studio: {
          location: {
            errors: {
              location_type_not_in_list: "n'est pas dans la liste des types",
              icon_not_in_list: "n'est pas dans la liste des icônes",
              country_code_iso: "doit être un code pays ISO à deux lettres",
              must_be_a_number: "doit être un nombre"
            }
          }
        }
      }
    )

    RecordingStudioLocation.configuration.icon_mode = :choose

    I18n.with_locale(:fr) do
      location = RecordingStudio::Location::Location.new(
        location_type: "warehouse",
        icon: "sparkles",
        country_code: "Australia",
        longitude: "north"
      )

      refute location.valid?

      assert_equal [{ error: :inclusion, value: "warehouse" }], location.errors.details[:location_type]
      assert_equal [{ error: :invalid, value: "AUSTRALIA" }], location.errors.details[:country_code]
      assert_includes location.errors.details[:longitude], { error: "doit être un nombre" }
      assert_includes location.errors.full_messages.join(" "), "n'est pas dans la liste des types"
      assert_includes location.errors.full_messages.join(" "), "n'est pas dans la liste des icônes"
      assert_includes location.errors.full_messages.join(" "), "doit être un code pays ISO à deux lettres"
      assert_includes location.errors.full_messages.join(" "), "doit être un nombre"
    end
  end

  test "host override wins for validation messages" do
    host = Rails.root.join("test/locales/location_host_override.en.yml")
    assert File.exist?(host), "expected test-only host override at #{host}"

    I18n.load_path = @previous_load_path + [host.to_s]
    I18n.reload!

    RecordingStudioLocation.configuration.icon_mode = :choose
    location = RecordingStudio::Location::Location.new(
      location_type: "warehouse",
      icon: "sparkles",
      country_code: "Australia",
      longitude: "north"
    )

    refute location.valid?

    assert_includes location.errors[:location_type], "HOST is not in the list of types"
    assert_includes location.errors[:icon], "HOST is not in the list of icons"
    assert_includes location.errors[:country_code], "HOST must be a two-letter ISO country code"
    assert_includes location.errors.details[:longitude], { error: "HOST must be a number" }
  ensure
    I18n.load_path = @previous_load_path
    I18n.backend = @previous_backend
  end

  private

  def snapshot_configuration
    configuration = RecordingStudioLocation.configuration
    {
      location_types: configuration.location_types.deep_dup,
      icon_mode: configuration.icon_mode,
      allowed_icons: configuration.allowed_icons.dup,
      default_icon: configuration.default_icon
    }
  end

  def restore_configuration(snapshot)
    configuration = RecordingStudioLocation.configuration
    configuration.location_types = snapshot.fetch(:location_types)
    configuration.icon_mode = snapshot.fetch(:icon_mode)
    configuration.allowed_icons = snapshot.fetch(:allowed_icons)
    configuration.default_icon = snapshot.fetch(:default_icon)
  end
end
