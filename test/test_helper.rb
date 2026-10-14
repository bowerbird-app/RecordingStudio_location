# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "simplecov_helper"
require "minitest/autorun"
begin
  require "minitest/mock"
rescue LoadError
  # Minitest 6 extracts Object#stub into the minitest-mock gem. The dummy
  # bundle does not load that gem; only the gem suite stubs methods.
end
require "rails"
require "active_support/time"
Time.zone ||= "UTC"
require "recording_studio_location"

# Gem suite does not boot the engine initializer. Register location English the
# same way the engine does at host boot so RecordingStudio.t fallback matches
# production regardless of test order.
if defined?(RecordingStudio::Translation) &&
   RecordingStudio::Translation.respond_to?(:register_shipped_english)
  RecordingStudio::Translation.register_shipped_english(
    File.expand_path("../config/locales/en.yml", __dir__)
  )
  RecordingStudio::Translation.reset_shipped_english!
  RecordingStudio::Translation.shipped_english
end
