# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"
require "generators/recording_studio_location/install/install_generator"

class InstallGeneratorTest < Minitest::Test
  INSTALL_TEMPLATE_PATH = File.expand_path(
    "../lib/generators/recording_studio_location/install/templates/INSTALL.md",
    __dir__
  )

  def with_temp_app
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "app/assets/tailwind"))
      yield dir
    end
  end

  def build_generator(destination_root, options = {})
    RecordingStudioLocation::Generators::InstallGenerator.new(
      [],
      options,
      destination_root: destination_root
    )
  end

  def test_mount_engine_uses_configured_mount_path
    generator = build_generator("/tmp", mount_path: "/addons/recording")
    routes = []

    generator.stub(:route, ->(value) { routes << value }) do
      generator.mount_engine
    end

    assert_equal ["mount RecordingStudioLocation::Engine, at: \"/addons/recording\""], routes
  end

  def test_add_tailwind_source_injects_engine_and_flatpack_sources
    with_temp_app do |dir|
      css_path = File.join(dir, "app/assets/tailwind/application.css")
      File.write(css_path, "@import \"tailwindcss\";\n")

      generator = build_generator(dir)

      Rails.stub(:root, Pathname.new(dir)) do
        generator.stub(:say, nil) do
          generator.add_tailwind_source
        end
      end

      css = File.read(css_path)
      assert_tailwind_sources_present(css)
    end
  end

  def test_add_tailwind_source_does_not_duplicate_existing_entries
    with_temp_app do |dir|
      css_path = File.join(dir, "app/assets/tailwind/application.css")
      File.write(css_path, <<~CSS)
        @import "tailwindcss";
        @source "../../vendor/bundle/**/recording_studio_location/app/views/**/*.erb";
        @source "../../../../../../usr/local/bundle/ruby/**/bundler/gems/recording_studio_location-*/app/views/**/*.erb";
        @source "../../vendor/bundle/**/flatpack/app/components/**/*.{rb,erb}";
        @source "../../../../../../usr/local/bundle/ruby/**/bundler/gems/flatpack-*/app/components/**/*.{rb,erb}";
      CSS

      generator = build_generator(dir)

      Rails.stub(:root, Pathname.new(dir)) do
        generator.stub(:say, nil) do
          generator.add_tailwind_source
        end
      end

      css = File.read(css_path)
      assert_tailwind_sources_present(css)
      assert_tailwind_sources_count(css, 1)
    end
  end

  def test_add_tailwind_source_reports_missing_tailwind_config
    with_temp_app do |dir|
      FileUtils.rm_rf(File.join(dir, "app/assets/tailwind"))
      generator = build_generator(dir)
      messages = []

      Rails.stub(:root, Pathname.new(dir)) do
        generator.stub(:say, ->(message, color = nil) { messages << [message, color] }) do
          generator.add_tailwind_source
        end
      end

      assert_includes messages, ["Tailwind CSS not detected. Skipping Tailwind configuration.", :yellow]
      assert_includes messages, ["If you use Tailwind, add these lines to your Tailwind CSS config:", :yellow]
      tailwind_source_lines.each do |line|
        assert_includes messages, ["  #{line}", :yellow]
      end
    end
  end

  def test_add_tailwind_source_reports_manual_configuration_when_import_is_missing
    with_temp_app do |dir|
      css_path = File.join(dir, "app/assets/tailwind/application.css")
      File.write(css_path, "@source \"../local/**/*.erb\";\n")
      generator = build_generator(dir)
      messages = []

      Rails.stub(:root, Pathname.new(dir)) do
        generator.stub(:say, ->(message, color = nil) { messages << [message, color] }) do
          generator.add_tailwind_source
        end
      end

      assert_equal "@source \"../local/**/*.erb\";\n", File.read(css_path)
      assert_includes messages, ["Could not find @import \"tailwindcss\" in your Tailwind config.", :yellow]
      assert_includes messages, ["Please manually add these lines to your Tailwind CSS config:", :yellow]
      tailwind_source_lines.each do |line|
        assert_includes messages, ["  #{line}", :yellow]
      end
    end
  end

  def test_show_readme_displays_install_guide_for_invoke_behavior
    generator = build_generator("/tmp")
    shown_templates = []

    generator.stub(:behavior, :invoke) do
      generator.stub(:readme, ->(template) { shown_templates << template }) do
        generator.show_readme
      end
    end

    assert_equal ["INSTALL.md"], shown_templates
  end

  def test_install_guide_includes_migration_and_host_setup_steps
    install_guide = File.read(INSTALL_TEMPLATE_PATH)

    assert_includes install_guide, "bin/rails generate recording_studio_location:migrations"
    assert_includes install_guide, "bin/rails db:migrate"
    assert_includes install_guide, "auth, layout, and current actor integration"
    assert_includes install_guide, "recording_studio_recordable"
    refute_includes install_guide, "RecordingStudio v3"
  end

  def test_add_importmap_pin_appends_controller_pin
    with_temp_app do |dir|
      FileUtils.mkdir_p(File.join(dir, "config"))
      importmap_path = File.join(dir, "config/importmap.rb")
      File.write(importmap_path, "pin \"application\"\n")
      generator = build_generator(dir)

      Rails.stub(:root, Pathname.new(dir)) do
        generator.stub(:say, nil) do
          generator.stub(:append_to_file, lambda { |path, content|
            File.write(path, File.read(path) + content)
          }) do
            generator.add_importmap_pin
          end
        end
      end

      pinned = File.read(importmap_path)
      assert_includes pinned, "recording_studio_location/controllers"
      assert_includes pinned, "place search"
    end
  end

  def test_initializer_template_wires_geocoder_from_credentials
    initializer = File.read(
      File.expand_path(
        "../lib/generators/recording_studio_location/install/templates/recording_studio_location_initializer.rb",
        __dir__
      )
    )

    assert_includes initializer, "RecordingStudioLocation::Geocoder.from_rails_credentials"
    assert_includes initializer, "RecordingStudioLocation::Map.from_rails_credentials"
    assert_includes initializer, "config.lookup_depth = :full"
    assert_includes initializer, "config.authenticate"
    assert_includes initializer, "config.icon_mode = :type"
    assert_includes initializer, "config.location_types"
    assert_includes initializer, "config.allowed_icons"
    assert_includes initializer, "config.default_icon"
    refute_includes initializer, "Reserved for a future geocoding adapter"
  end

  private

  def assert_tailwind_sources_present(css)
    tailwind_source_lines.each do |line|
      assert_includes css, line
    end
  end

  def assert_tailwind_sources_count(css, count)
    tailwind_source_lines.each do |line|
      assert_equal count, css.scan(line).size
    end
  end

  def tailwind_source_lines
    [
      '@source "../../vendor/bundle/**/recording_studio_location/app/views/**/*.erb";',
      gem_source("recording_studio_location-*/app/views/**/*.erb"),
      '@source "../../vendor/bundle/**/flatpack/app/components/**/*.{rb,erb}";',
      gem_source("flatpack-*/app/components/**/*.{rb,erb}")
    ]
  end

  def gem_source(path)
    %(@source "../../../../../../usr/local/bundle/ruby/**/bundler/gems/#{path}";)
  end
end
