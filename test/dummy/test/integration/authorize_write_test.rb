# frozen_string_literal: true

require "test_helper"

class AuthorizeWriteTest < ActiveSupport::TestCase
  include AccessibleGrants

  test "dummy authorize_write is configured and is not actor presence" do
    initializer = File.read(Rails.root.join("config/initializers/recording_studio.rb"))

    assert_includes initializer, "config.authorize_write"
    assert_includes initializer, "RecordingStudioAccessible.authorized?"
    assert_includes initializer, "AccessCreationContext.allowed?"
    refute_match(/authorize_write\s*=\s*->\(actor:, \*\*\) \{ actor\.present\? \}/, initializer)
    refute_includes initializer, "allow_unauthorized_writes = true"
  end

  test "dummy authorize_write requires Accessible edit on the root" do
    authorizer = RecordingStudio.configuration.authorize_write

    refute_nil authorizer

    actor = User.find_or_create_by!(email: "dummy-write-authorizer-#{SecureRandom.hex(4)}@example.com") do |record|
      record.password = "Password"
      record.password_confirmation = "Password"
    end
    workspace = Workspace.create!(name: "Write policy #{SecureRandom.hex(4)}")
    root_recording = RecordingStudio.root_recording_for(workspace)
    location = RecordingStudio::Location::Location.new(country_code: "AU")

    refute authorizer.call(actor: nil, root_recording: root_recording, recordable: location)
    refute authorizer.call(actor: actor, root_recording: root_recording, recordable: location)

    grant_admin_access!(actor: actor, recording: root_recording)

    assert authorizer.call(actor: actor, root_recording: root_recording, recordable: location)
  end

  test "AccessCreationContext allows only Access recordables" do
    authorizer = RecordingStudio.configuration.authorize_write
    actor = User.find_or_create_by!(email: "dummy-write-access-#{SecureRandom.hex(4)}@example.com") do |record|
      record.password = "Password"
      record.password_confirmation = "Password"
    end
    workspace = Workspace.create!(name: "Access policy #{SecureRandom.hex(4)}")
    root_recording = RecordingStudio.root_recording_for(workspace)
    location = RecordingStudio::Location::Location.new(country_code: "AU")
    access = RecordingStudio::Access.new

    RecordingStudioAccessible::AccessCreationContext.allow do
      refute authorizer.call(actor: actor, root_recording: root_recording, recordable: location)
      assert authorizer.call(actor: actor, root_recording: root_recording, recordable: access)
    end

    refute authorizer.call(actor: actor, root_recording: root_recording, recordable: access)

    grant_admin_access!(actor: actor, recording: root_recording)

    assert authorizer.call(actor: actor, root_recording: root_recording, recordable: access)
    assert authorizer.call(actor: actor, root_recording: root_recording, recordable: location)
  end
end
