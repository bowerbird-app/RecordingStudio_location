# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

# Behavioral renders: a locale without translations shows loaded / shipped
# English for Location form copy. Uses :de so boot-loaded host English
# overrides and other locales do not interfere with the missing-locale case.
class EnglishFallbackTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  TITLE_KEY = "recording_studio.location.fields.title"
  CLEAR_KEY = "recording_studio.location.search.clear"

  setup do
    @user = User.find_or_create_by!(email: "english-fallback@example.com") do |user|
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
    end
    sign_in @user
    @workspace = Workspace.find_or_create_by!(name: "Studio Workspace")
    RecordingStudio.root_recording_for(@workspace)
    @previous_locales = I18n.available_locales
    I18n.available_locales = (@previous_locales + %i[en de fr]).uniq
  end

  teardown do
    I18n.locale = I18n.default_locale
    I18n.available_locales = @previous_locales if @previous_locales
  end

  test "missing locale without translations renders gem english on new location page" do
    I18n.with_locale(:de) do
      refute locale_has_own_translation?(:de, TITLE_KEY),
             ":de must not ship its own fields.title (fallbacks may still resolve via :en)"

      get new_location_path

      assert_response :success
      assert_location_english_chrome!(@response.body)
    end
  end

  test "english render matches gem english strings from main" do
    I18n.with_locale(:en) do
      get new_location_path

      assert_response :success
      assert_location_english_chrome!(@response.body)
      assert_includes @response.body, "Search for a place or address"
    end
  end

  test "deleted english key on new location shows shipped Title without translation missing" do
    delete_loaded_translation!(:en, TITLE_KEY)
    delete_loaded_translation!(:fr, TITLE_KEY)
    delete_loaded_translation!(:en, CLEAR_KEY)
    delete_loaded_translation!(:fr, CLEAR_KEY)

    refute I18n.exists?(TITLE_KEY, :en)
    refute I18n.exists?(TITLE_KEY, :fr)

    previous_raise = ActionView::Helpers::TranslationHelper.raise_on_missing_translations

    [false, true].each do |raise_on_missing|
      ActionView::Helpers::TranslationHelper.raise_on_missing_translations = raise_on_missing

      %i[en fr].each do |locale|
        I18n.with_locale(locale) do
          get new_location_path

          assert_response :success
          assert_location_english_chrome!(@response.body)
        end
      end
    end
  ensure
    ActionView::Helpers::TranslationHelper.raise_on_missing_translations = previous_raise
    I18n.reload!
  end

  test "shipped english table becomes a new object after rails reloader reload" do
    before = RecordingStudio::Translation.shipped_english
    refute_empty before
    assert_equal "Title", before.fetch("recording_studio.location.fields.title")

    previous_cache_classes = Rails.application.config.cache_classes
    Rails.application.config.cache_classes = false
    RecordingStudioMetrics.registry.reset! if defined?(RecordingStudioMetrics)

    Rails.application.reloader.reload!

    after = RecordingStudio::Translation.shipped_english
    refute_same before, after
    assert_equal before.fetch("recording_studio.location.fields.title"),
                 after.fetch("recording_studio.location.fields.title")
  ensure
    Rails.application.config.cache_classes = previous_cache_classes unless previous_cache_classes.nil?
  end

  test "global I18n config keeps fallbacks load_path available_locales and exception handler" do
    snapshot = i18n_config_snapshot
    gem_en = File.expand_path(RecordingStudioLocation::Engine.root.join("config/locales/en.yml"))
    boot_en = Rails.root.join("config/locales/recording_studio_location_host.en.yml").to_s

    assert_includes snapshot.fetch(:load_path), File.expand_path(gem_en)
    assert_includes snapshot.fetch(:load_path), File.expand_path(boot_en)
    assert_operator snapshot.fetch(:load_path).index(File.expand_path(gem_en)),
                    :<,
                    snapshot.fetch(:load_path).index(File.expand_path(boot_en))
    assert snapshot.fetch(:exception_handler), "expected an I18n exception handler"
    assert_includes snapshot.fetch(:available_locales), :en
  end

  private

  def assert_location_english_chrome!(body)
    assert_select "h1", text: "New location"
    assert_includes body, "Title"
    assert_includes body, "Clear location"
    # FlatPack chrome may still say "Translation missing" under :de; ignore those.
    refute_match(/translation missing: [a-z]+\.recording_studio\.location/i, body)
    refute_includes body, "Translation missing: #{I18n.locale}.recording_studio.location"
  end

  def i18n_config_snapshot
    {
      load_path: I18n.load_path.map { |path| File.expand_path(path) },
      available_locales: Array(I18n.available_locales).map(&:to_sym).sort,
      exception_handler: I18n.exception_handler,
      enforce_available_locales: I18n.enforce_available_locales,
      fallbacks_class: (I18n.fallbacks.class.name if I18n.respond_to?(:fallbacks))
    }
  end

  def locale_has_own_translation?(locale, full_key)
    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    node = I18n.backend.send(:translations)[locale.to_sym]
    return false unless node.is_a?(Hash)

    full_key.split(".").map(&:to_sym).each do |part|
      return false unless node.is_a?(Hash) && node.key?(part)

      node = node[part]
    end
    !node.nil?
  end

  def delete_loaded_translation!(locale, full_key)
    I18n.exists?(full_key, locale)
    parts = full_key.split(".").map(&:to_sym)
    leaf = parts.pop
    translations = I18n.backend.send(:translations)
    locale_key = locale.to_sym
    translations[locale_key] = translations[locale_key].dup if translations[locale_key].frozen?

    node = translations[locale_key]
    parts.each do |part|
      break unless node.is_a?(Hash) && node[part].is_a?(Hash)

      node[part] = node[part].dup if node[part].frozen?
      node = node[part]
    end
    node.delete(leaf) if node.is_a?(Hash)
  end
end
