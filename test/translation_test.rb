# frozen_string_literal: true

require "test_helper"
require "action_controller"
require "action_view"
require "yaml"

# Points at RecordingStudio.t (no gem-local Translation helper). Location English
# is contributed via register_shipped_english on the gem en.yml path.
class TranslationTest < Minitest::Test
  GEM_KEYS = {
    "recording_studio.location.fields.title" => "Title",
    "recording_studio.location.search.clear" => "Clear location",
    "recording_studio.location.search.label" => "Location",
    "recording_studio.location.map.title" => "Map of this location",
    "recording_studio.location.errors.must_be_a_number" => "must be a number",
    "recording_studio.location.location_types.office" => "Office"
  }.freeze

  LOCATION_EN_YML = File.expand_path("../config/locales/en.yml", __dir__)

  def setup
    @previous_locales = I18n.available_locales
    I18n.available_locales = (@previous_locales + %i[en fr de xx]).uniq
    ensure_location_english_registered!
    reset_english_backend!
    clear_locale_translations!(:de)
    clear_locale_translations!(:fr)
    clear_locale_translations!(:xx)
  end

  def teardown
    I18n.locale = I18n.default_locale
    I18n.available_locales = @previous_locales if @previous_locales
    clear_legacy_locale_translations!(:en)
    reset_english_backend!
    clear_locale_translations!(:de)
    clear_locale_translations!(:fr)
    clear_locale_translations!(:xx)
  end

  def test_english_locale_resolves_every_sample_gem_key_from_en_yml
    I18n.with_locale(:en) do
      GEM_KEYS.each do |key, english|
        assert_equal english, RecordingStudio.t(key)
        relative = key.delete_prefix("recording_studio.location.")
        assert_equal english, RecordingStudioLocation::Copy.t(relative)
      end
    end
  end

  def test_location_en_yml_path_is_registered_with_recording_studio_translation
    # Must fail on its own when registration is missing: do not call the engine
    # initializer block here — path must already be registered (test_helper /
    # engine boot).
    expected = File.expand_path(LOCATION_EN_YML)
    paths = RecordingStudio::Translation.send(:registered_shipped_english_paths)

    assert_includes paths, expected
    assert_equal "Title",
                 RecordingStudio::Translation.shipped_english.fetch(
                   "recording_studio.location.fields.title"
                 )
  end

  def test_shipped_english_table_includes_registered_location_en_yml
    RecordingStudio::Translation.reset_shipped_english!
    en_yml = YAML.safe_load_file(LOCATION_EN_YML, aliases: true)
                 .fetch("en").fetch("recording_studio").fetch("location")
    expected = flatten_locale_keys(en_yml, %w[recording_studio location])
    table = RecordingStudio::Translation.shipped_english

    expected.each do |key, english|
      assert_equal english, table.fetch(key), "#{key} must be in the merged shipped table"
    end
    assert_predicate table, :frozen?
    assert_same table, RecordingStudio::Translation.shipped_english,
                "shipped english must be loaded once (no per-call file reload)"
  end

  def test_deleted_loaded_english_falls_back_to_shipped_gem_en_yml_text
    GEM_KEYS.each_key do |key|
      delete_loaded_translation!(:en, key)
      delete_loaded_translation!(:fr, key)
    end

    GEM_KEYS.each do |key, english|
      refute I18n.exists?(key, :en), "#{key} must be absent from loaded :en"
      I18n.with_locale(:en) do
        assert_equal english, RecordingStudio.t(key)
        refute_match(/translation missing/i, RecordingStudio.t(key))
        relative = key.delete_prefix("recording_studio.location.")
        assert_equal english, RecordingStudioLocation::Copy.t(relative)
      end
      I18n.with_locale(:fr) do
        assert_equal english, RecordingStudio.t(key)
        refute_match(/translation missing/i, RecordingStudio.t(key))
      end
    end
  ensure
    I18n.backend.store_translations(:en, gem_english_tree)
  end

  def test_missing_locale_falls_back_to_loaded_english
    I18n.with_locale(:de) do
      GEM_KEYS.each do |key, english|
        refute I18n.exists?(key, :de), "#{key} must be absent in :de for this test"
        assert_equal english, RecordingStudio.t(key),
                     "#{key} should fall back to loaded English when :de has no file"
        refute_match(/translation missing/i, RecordingStudio.t(key))
      end
    end
  end

  def test_does_not_raise_for_missing_locale_when_callers_use_raise_on_missing_style_lookups
    I18n.with_locale(:de) do
      assert_raises(I18n::MissingTranslationData) do
        I18n.t("recording_studio.location.fields.title", locale: :de, raise: true)
      end

      assert_equal "Title",
                   RecordingStudio.t("recording_studio.location.fields.title")
    end
  end

  def test_english_fallback_value_matches_loaded_en_backend_not_a_ruby_literal_table
    en_yml = YAML.safe_load_file(LOCATION_EN_YML, aliases: true)
    gem_english = en_yml.fetch("en").fetch("recording_studio").fetch("location")
                        .fetch("fields").fetch("title")

    source = File.read(File.expand_path("../lib/recording_studio_location/copy.rb", __dir__))
    refute_includes source, gem_english,
                    "Copy must not hard-code English; it must use RecordingStudio.t"

    I18n.with_locale(:de) do
      assert_equal gem_english, RecordingStudio.t("recording_studio.location.fields.title")
    end
  end

  def test_parity_matrix_non_gem_keys_match_i18n_t
    # I18n template tokens use %{name}; RuboCop prefers %<name>s for Kernel#sprintf.
    # rubocop:disable Style/FormatStringToken
    I18n.backend.store_translations(:en, {
                                      probe: {
                                        greet: "Hi %{name}",
                                        empty: "",
                                        nil_value: nil,
                                        nest: { a: "A" },
                                        html_key_html: "<b>x</b>",
                                        items: { one: "one item", other: "%{count} items" }
                                      }
                                    })
    I18n.backend.store_translations(:de, { probe: { greet: "Hallo %{name}" } })
    # rubocop:enable Style/FormatStringToken

    I18n.with_locale(:de) do
      assert_parity("probe.greet", name: "M")
      assert_parity("probe.missing")
      assert_parity("probe.missing", default: "D")
      assert_parity("probe.empty")
      assert_parity("probe.nil_value")
      assert_parity("probe.nest")
      assert_parity("probe.items", count: 1)
      assert_parity("probe.items", count: 5)
      assert_parity(:"probe.greet", name: "M")
      assert_parity(%w[probe.missing probe.greet], name: "M")
      assert_parity("greet", scope: "probe", name: "M")
      assert_raise_parity("probe.missing", raise: true)
      assert_parity("probe.greet", locale: :en, name: "M")
      assert_parity("probe.html_key_html")
    end
  end

  def test_parity_matrix_gem_keys_cover_missing_default_raise_nil_empty_hash_and_related_options
    key = "recording_studio.location.fields.title"
    missing = "recording_studio.location.fields.missing_key_for_parity"

    # I18n template tokens use %{name}; RuboCop prefers %<name>s for Kernel#sprintf.
    # rubocop:disable-next Style/FormatStringToken
    I18n.backend.store_translations(:en, {
                                      recording_studio: {
                                        location: {
                                          fields: {
                                            nil_value: nil,
                                            empty_value: "",
                                            nest: { a: "A" },
                                            html_key_html: "<i>g</i>",
                                            items: { one: "one", other: "%{count} many" },
                                            greet: "Hi %{name}"
                                          }
                                        }
                                      }
                                    })

    I18n.with_locale(:en) do
      assert_equal I18n.t(key), RecordingStudio.t(key)
      assert_equal "Title", RecordingStudio.t(key, default: "Ignored when present")
    end

    # rubocop:disable-next Metrics/BlockLength -- gem-key parity matrix against I18n.t
    I18n.with_locale(:de) do
      assert_equal "Title", RecordingStudio.t(key),
                   "missing active locale uses loaded English"
      assert_match(/translation missing/i, I18n.t(key))

      assert_parity(missing)
      assert_parity(missing, default: "D")
      assert_raise_parity(missing, raise: true)

      I18n.backend.store_translations(:de, {
                                        recording_studio: { location: { fields: { title: "DE Titel" } } }
                                      })
      assert_equal "DE Titel", RecordingStudio.t(key)
      assert_equal I18n.t(key), RecordingStudio.t(key),
                   "no English fallback when the active locale has the key"

      assert_parity("recording_studio.location.fields.nil_value")
      assert_equal "", RecordingStudio.t("recording_studio.location.fields.empty_value")
      assert_match(/translation missing/i, I18n.t("recording_studio.location.fields.empty_value"))

      assert_equal(
        I18n.t("recording_studio.location.fields.nest", locale: :en),
        RecordingStudio.t("recording_studio.location.fields.nest")
      )
      assert_equal(
        I18n.t("recording_studio.location.fields.items", locale: :en, count: 1),
        RecordingStudio.t("recording_studio.location.fields.items", count: 1)
      )
      assert_equal(
        I18n.t("recording_studio.location.fields.greet", locale: :en, name: "M"),
        RecordingStudio.t("recording_studio.location.fields.greet", name: "M")
      )

      assert_equal "DE Titel", RecordingStudio.t(:"recording_studio.location.fields.title")
      assert_equal(
        ["DE Titel", "Clear location"],
        RecordingStudio.t(%w[
                            recording_studio.location.fields.title
                            recording_studio.location.search.clear
                          ])
      )
      assert_equal "DE Titel", RecordingStudio.t(:title, scope: "recording_studio.location.fields")

      assert_equal(
        "Name",
        RecordingStudio.t(:name, scope: "recording_studio.location.fields"),
        "scope: gem key missing in :de must fall back to English"
      )

      html = RecordingStudio.t("recording_studio.location.fields.html_key_html")
      assert_equal "<i>g</i>", html
      assert_predicate html, :html_safe?

      assert_equal "D", RecordingStudio.t(missing, default: "D")

      I18n.backend.store_translations(:en, {
                                        recording_studio: {
                                          location: { fields: { missing_key_for_parity: "EN" } }
                                        }
                                      })
      assert_equal "EN", RecordingStudio.t(missing, default: "D")

      error = assert_raises(I18n::MissingTranslationData) do
        RecordingStudio.t("recording_studio.location.fields.totally_absent", raise: true)
      end
      assert_match(/Translation missing: de\.recording_studio/, error.message)

      assert_equal "Title", RecordingStudio.t(key, locale: :en)
    end
  end

  def test_fallback_order_prefers_loaded_english_then_caller_default_over_shipped_table
    key = "recording_studio.location.fields.title"

    write_loaded_translation!(:en, key, "HOST EN Title")
    I18n.with_locale(:de) do
      refute I18n.exists?(key, :de)
      assert_equal "HOST EN Title", RecordingStudio.t(key),
                   "host :en override must win over the gem-shipped table"
    end

    delete_loaded_translation!(:en, key)
    delete_loaded_translation!(:fr, key)
    %i[en fr de].each do |locale|
      I18n.with_locale(locale) do
        assert_equal "CALLER", RecordingStudio.t(key, default: "CALLER"),
                     "caller default: must come before the gem-shipped table in #{locale}"
        assert_equal "Title", RecordingStudio.t(key),
                     "gem-shipped table is used last in #{locale}"
      end
    end
  ensure
    I18n.backend.store_translations(:en, gem_english_tree)
  end

  def test_html_gem_keys_escape_unsafe_interpolation_like_view_t
    # I18n template tokens use %{name}; RuboCop prefers %<name>s for Kernel#sprintf.
    # rubocop:disable-next Style/FormatStringToken
    I18n.backend.store_translations(:en, {
                                      recording_studio: {
                                        location: {
                                          probe: {
                                            hi_html: "<b>Hi %{name}</b>",
                                            greet: "Hi %{name}",
                                            items_html: {
                                              one: "<i>1 x</i>",
                                              other: "<i>%{count} xs</i>"
                                            }
                                          }
                                        }
                                      }
                                    })
    view = ActionController::Base.helpers

    # rubocop:disable-next Metrics/BlockLength -- html_safe / escaping parity vs view t
    I18n.with_locale(:en) do
      value = RecordingStudio.t("recording_studio.location.probe.hi_html", name: "<script>")
      assert_equal "<b>Hi &lt;script&gt;</b>", value
      assert_predicate value, :html_safe?
      assert_equal view.t("recording_studio.location.probe.hi_html", name: "<script>"), value

      plain = RecordingStudio.t("recording_studio.location.probe.greet", name: "<s>")
      assert_equal "Hi <s>", plain
      refute_predicate plain, :html_safe?
      assert_equal view.t("recording_studio.location.probe.greet", name: "<s>"), plain

      safe_arg = "<u>ok</u>".html_safe
      with_safe = RecordingStudio.t("recording_studio.location.probe.hi_html", name: safe_arg)
      assert_equal "<b>Hi <u>ok</u></b>", with_safe
      assert_equal view.t("recording_studio.location.probe.hi_html", name: safe_arg), with_safe

      plural = RecordingStudio.t("recording_studio.location.probe.items_html", count: 2)
      assert_equal "<i>2 xs</i>", plural
      assert_predicate plural, :html_safe?
      assert_equal view.t("recording_studio.location.probe.items_html", count: 2), plural

      singular = RecordingStudio.t("recording_studio.location.probe.items_html", count: 1)
      assert_equal "<i>1 x</i>", singular
      assert_predicate singular, :html_safe?
      assert_equal view.t("recording_studio.location.probe.items_html", count: 1), singular

      missing_html = "recording_studio.location.probe.missing_key_html"
      reserved = RecordingStudio.t(missing_html, default: "<b>ok</b>")
      assert_equal "<b>ok</b>", reserved
      refute_predicate reserved, :html_safe?
      assert_equal view.t(missing_html, default: "<b>ok</b>"), reserved

      # Array caller defaults are marked html_safe by RecordingStudio.t
      # (stricter than view t, which leaves them unsafe).
      array_default = RecordingStudio.t(missing_html, default: ["<b>arr</b>"])
      assert_equal "<b>arr</b>", array_default
      assert_predicate array_default, :html_safe?

      xss = RecordingStudio.t(
        "recording_studio.location.probe.hi_html",
        name: "<script>alert(1)</script>"
      )
      assert_equal "<b>Hi &lt;script&gt;alert(1)&lt;/script&gt;</b>", xss
      assert_predicate xss, :html_safe?
    end
  end

  def test_shipped_english_table_is_present_after_boot_registration
    table = RecordingStudio::Translation.shipped_english
    refute_nil table
    refute_empty table
    assert_equal "Title", table.fetch("recording_studio.location.fields.title")
  end

  def test_shipped_english_table_becomes_a_new_object_after_reload_reset
    before = RecordingStudio::Translation.shipped_english
    RecordingStudio::Translation.reset_shipped_english!
    after = RecordingStudio::Translation.shipped_english

    refute_same before, after
    assert_equal before, after
    assert_predicate after, :frozen?
  end

  def test_registered_missing_en_yml_contributes_empty_without_raising
    RecordingStudio::Translation.register_shipped_english(
      File.expand_path("no_such_location_en.yml", Dir.tmpdir)
    )
    RecordingStudio::Translation.reset_shipped_english!

    table = RecordingStudio::Translation.shipped_english
    assert_equal "Title", table.fetch("recording_studio.location.fields.title")
    refute table.key?("recording_studio.location.from_missing_file")
  end

  def test_lazy_keys_pass_through_like_i18n_t
    I18n.with_locale(:en) do
      assert_equal I18n.t(".lazy_key_without_scope"), RecordingStudio.t(".lazy_key_without_scope")
    end
  end

  def test_nil_key_does_not_raise
    I18n.with_locale(:en) do
      expected = I18n.t(nil)
      actual = RecordingStudio.t(nil)
      if expected.nil?
        assert_nil actual
      else
        assert_equal expected, actual
      end
    end
  end

  def test_global_i18n_config_snapshot_is_unchanged_by_recording_studio_t
    before = i18n_config_snapshot

    RecordingStudio.t("recording_studio.location.fields.title")
    I18n.with_locale(:de) do
      RecordingStudio.t("recording_studio.location.fields.title")
      RecordingStudio.t("not_a_gem_key")
    end

    assert_equal before, i18n_config_snapshot
  end

  def test_copy_t_uses_recording_studio_t_only_for_nested_gem_keys
    source = File.read(File.expand_path("../lib/recording_studio_location/copy.rb", __dir__))
    assert_includes source, "RecordingStudio.t"
    assert_includes source, "I18n.t"
    assert_match(/I18n\.exists\?\(legacy_key/, source)
    assert_match(/I18n\.t\(legacy_key/, source)
  end

  def test_legacy_host_keys_resolve_through_i18n_t_not_recording_studio_t_fallback
    I18n.backend.store_translations(
      :en,
      recording_studio_location: { fields: { title: "Place name" } }
    )
    delete_loaded_translation!(:en, "recording_studio.location.fields.title")

    I18n.with_locale(:en) do
      assert_equal "Place name", RecordingStudioLocation::Copy.t("fields.title")
      # Nested gem key still falls back via RecordingStudio.t / shipped table.
      assert_equal "Clear location", RecordingStudioLocation::Copy.t("search.clear")
    end
  ensure
    clear_legacy_locale_translations!(:en)
    I18n.backend.store_translations(:en, gem_english_tree)
  end

  private

  def ensure_location_english_registered!
    # Never call the engine initializer block or register here — registration
    # must already exist (test_helper for the gem suite, engine boot for dummy).
    expected = File.expand_path(LOCATION_EN_YML)
    paths = RecordingStudio::Translation.send(:registered_shipped_english_paths)
    raise "location en.yml is not registered; test_helper/engine must register it" unless paths.include?(expected)

    RecordingStudio::Translation.reset_shipped_english!
    RecordingStudio::Translation.shipped_english
  end

  def clear_legacy_locale_translations!(locale)
    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    translations = I18n.backend.send(:translations)
    locale_key = locale.to_sym
    node = translations[locale_key]
    return unless node.is_a?(Hash)

    translations[locale_key] = node.dup if node.frozen?
    translations[locale_key].delete(:recording_studio_location) if translations[locale_key].is_a?(Hash)
  end

  def assert_parity(key, **options)
    expected = I18n.t(key, **options)
    actual = RecordingStudio.t(key, **options)
    assert_equal expected, actual, "parity failed for #{key.inspect} options=#{options.inspect}"
    return unless actual.is_a?(String) && key.to_s.match?(/(\b|_|\.)html\z/)

    assert_equal expected.html_safe?, actual.html_safe?
  end

  def assert_raise_parity(key, **options)
    i18n_error = assert_raises(I18n::MissingTranslationData) { I18n.t(key, **options) }
    rs_error = assert_raises(I18n::MissingTranslationData) { RecordingStudio.t(key, **options) }
    assert_equal i18n_error.message, rs_error.message
  end

  def i18n_config_snapshot
    {
      load_path: I18n.load_path.map { |path| File.expand_path(path) },
      available_locales: Array(I18n.available_locales).map(&:to_sym).sort,
      exception_handler: I18n.exception_handler,
      enforce_available_locales: I18n.enforce_available_locales
    }
  end

  def flatten_locale_keys(node, prefix)
    case node
    when Hash
      node.each_with_object({}) do |(key, value), result|
        result.merge!(flatten_locale_keys(value, prefix + [key.to_s]))
      end
    else
      { prefix.join(".") => node }
    end
  end

  def gem_english_tree
    YAML.safe_load_file(LOCATION_EN_YML, aliases: true).fetch("en")
  end

  def reset_english_backend!
    I18n.backend.store_translations(:en, gem_english_tree)
  end

  def clear_locale_translations!(locale)
    I18n.backend.send(:init_translations) unless I18n.backend.initialized?
    translations = I18n.backend.send(:translations)
    locale_key = locale.to_sym
    node = translations[locale_key]
    return unless node.is_a?(Hash)

    translations[locale_key] = node.dup if node.frozen?
    translations[locale_key].delete(:recording_studio) if translations[locale_key].is_a?(Hash)
  end

  def delete_loaded_translation!(locale, full_key)
    mutate_loaded_translation!(locale, full_key) { |node, leaf| node.delete(leaf) }
  end

  def write_loaded_translation!(locale, full_key, value)
    mutate_loaded_translation!(locale, full_key) { |node, leaf| node[leaf] = value }
  end

  # rubocop:disable-next Metrics/CyclomaticComplexity -- walks a frozen I18n tree safely
  def mutate_loaded_translation!(locale, full_key)
    I18n.exists?(full_key, locale) # ensure translations are loaded / initialized
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
    yield node, leaf if node.is_a?(Hash)
  end
end
