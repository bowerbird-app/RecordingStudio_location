# frozen_string_literal: true

# Isolated boot used by MissingAccessibleSearchBootTest.
# The gem suite Gemfile does not include recording_studio_accessible. This process
# mounts the Location engine and hits searches after identity succeeds.

ENV["RAILS_ENV"] = "test"

require "json"
require "logger"
require "tmpdir"
require "fileutils"
require "pathname"

if defined?(RecordingStudioAccessible) || Gem.loaded_specs.key?("recording_studio_accessible")
  warn({ error: "accessible_present_before_boot" }.to_json)
  exit 1
end

root = Dir.mktmpdir("location-missing-accessible")
FileUtils.mkdir_p(File.join(root, "config"))
File.write(File.join(root, "config.ru"), "run Rails.application")
File.write(File.join(root, "config", "application.rb"), "# isolated missing-accessible host")
File.write(File.join(root, "config", "routes.rb"), <<~RUBY)
  IsolatedLocation::Application.routes.draw do
    mount RecordingStudioLocation::Engine => "/recording_studio_location"
  end
RUBY
Dir.chdir(root)

require "rails"
require "active_record"
require "action_controller/railtie"
require "action_view/railtie"
require "recording_studio_location"

if defined?(RecordingStudioAccessible) || Gem.loaded_specs.key?("recording_studio_accessible")
  warn({ error: "accessible_present_after_require" }.to_json)
  exit 1
end

RecordingStudio.configure do |config|
  config.recordable_types = ["RecordingStudio::Location::Location"]
  config.require_recordable_declarations = false
end

module IsolatedLocation
  class Application < Rails::Application
    config.root = Pathname.new(root)
    config.load_defaults 8.1
    config.eager_load = false
    config.enable_reloading = false
    config.consider_all_requests_local = true
    config.secret_key_base = "isolated-missing-accessible" * 2
    config.logger = Logger.new(nil)
    config.action_dispatch.show_exceptions = :none
    config.hosts.clear
    config.session_store :cookie_store, key: "_isolated"
    config.action_controller.allow_forgery_protection = false
  end
end

IsolatedLocation::Application.initialize!

RecordingStudioLocation.configure do |config|
  config.authenticate = ->(_controller) {}
end

status, _headers, _body = Rails.application.call(
  Rack::MockRequest.env_for(
    "/recording_studio_location/searches?q=melbourne",
    "HTTP_ACCEPT" => "application/json",
    "REQUEST_METHOD" => "GET"
  )
)

puts({
  status: status,
  accessible_defined: defined?(RecordingStudioAccessible),
  accessible_gem: Gem.loaded_specs.key?("recording_studio_accessible")
}.to_json)
