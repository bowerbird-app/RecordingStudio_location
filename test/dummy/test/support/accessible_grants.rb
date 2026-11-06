# frozen_string_literal: true

module AccessibleGrants
  STUDIO_WRITER_PASSWORD = "Password123!"

  def grant_admin_access!(actor:, recording:)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: actor)
    return recording if result.success?

    message = result.error.respond_to?(:message) ? result.error.message : result.error.to_s
    raise "Failed to grant Accessible admin on #{recording.id}: #{message}"
  end

  def become_studio_writer!(recording, actor: nil)
    writer = actor || studio_writer_for(recording)
    unless RecordingStudioAccessible.authorized?(actor: writer, recording: recording, role: :edit)
      grant_admin_access!(actor: writer, recording: recording)
    end
    Current.actor = writer
    writer
  end

  def with_studio_writer(recording, actor: nil)
    previous = Current.actor
    become_studio_writer!(recording, actor: actor)
    yield Current.actor
  ensure
    Current.actor = previous
  end

  def studio_writer_for(recording)
    User.find_or_create_by!(email: "studio-writer-#{recording.id}@example.com") do |user|
      user.password = STUDIO_WRITER_PASSWORD
      user.password_confirmation = STUDIO_WRITER_PASSWORD
    end
  end
end
