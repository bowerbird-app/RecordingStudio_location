# frozen_string_literal: true

require "test_helper"
require "json"
require "open3"

class MissingAccessibleSearchBootTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  BOOT = File.expand_path("support/missing_accessible_search_boot.rb", __dir__)
  GEMFILE = File.expand_path("../Gemfile", __dir__)

  def test_signed_in_search_is_forbidden_when_accessible_gem_is_absent
    refute_includes File.read(GEMFILE), "recording_studio_accessible"
    refute defined?(::RecordingStudioAccessible)

    stdout, stderr, status = Bundler.with_unbundled_env do
      Open3.capture3(
        {
          "BUNDLE_GEMFILE" => GEMFILE,
          "RAILS_ENV" => "test"
        },
        "bundle", "exec", "ruby", BOOT,
        chdir: ROOT
      )
    end

    assert status.success?, "isolated boot failed (#{status.exitstatus}): #{stderr}\n#{stdout}"

    payload = JSON.parse(stdout.lines.last)
    assert_nil payload["accessible_defined"]
    refute payload["accessible_gem"]
    assert_equal 403, payload["status"]
  end
end
