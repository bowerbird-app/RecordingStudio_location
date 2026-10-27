# frozen_string_literal: true

# Sibling git tags still declare recording_studio < 5. Bundler reads
# Gem::Specification#dependencies while it resolves, so this has to run
# before those gemspecs load.
#
# Return the same array. Gem::Specification#add_dependency appends to
# whatever #dependencies returns, and a copy would drop every dependency.
module WidenRecordingStudioRequirement
  NAME = "recording_studio"
  ALLOWED = Gem::Version.new("6.1.0")

  module Relaxer
    def dependencies
      deps = super
      deps.each { |dependency| WidenRecordingStudioRequirement.relax!(dependency) }
      deps
    end
  end

  def self.relax!(dependency)
    return unless dependency.name == NAME
    return if dependency.requirement.satisfied_by?(ALLOWED)

    dependency.instance_variable_set(:@requirement, Gem::Requirement.new(">= #{ALLOWED}"))
  end

  def self.apply!
    return if Gem::Specification < Relaxer

    Gem::Specification.prepend(Relaxer)
  end
end

WidenRecordingStudioRequirement.apply!
