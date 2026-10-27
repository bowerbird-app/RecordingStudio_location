# frozen_string_literal: true

require "test_helper"
require_relative "support/widen_recording_studio_requirement"

class WidenRecordingStudioRequirementTest < Minitest::Test
  def test_relax_keeps_the_dependency_array_and_allows_recording_studio_6_1
    spec = Gem::Specification.new
    spec.name = "sibling"
    spec.version = "0.0.1"
    spec.add_dependency "recording_studio", "~> 4.2"
    spec.add_dependency "rails", ">= 8.1"

    recording_studio = spec.dependencies.find { |dependency| dependency.name == "recording_studio" }
    rails = spec.dependencies.find { |dependency| dependency.name == "rails" }

    assert_same spec.dependencies, spec.dependencies
    assert_equal 2, spec.dependencies.length
    assert recording_studio.requirement.satisfied_by?(Gem::Version.new("6.1.0"))
    assert rails.requirement.satisfied_by?(Gem::Version.new("8.1.0"))
    refute rails.requirement.satisfied_by?(Gem::Version.new("6.1.0"))
  end
end
