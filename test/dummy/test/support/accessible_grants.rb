# frozen_string_literal: true

module AccessibleGrants
  def grant_admin_access!(actor:, recording:)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: actor)
    return recording if result.success?

    message = result.error.respond_to?(:message) ? result.error.message : result.error.to_s
    raise "Failed to grant Accessible admin on #{recording.id}: #{message}"
  end
end
