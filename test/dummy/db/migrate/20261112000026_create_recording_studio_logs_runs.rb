# frozen_string_literal: true

class CreateRecordingStudioLogsRuns < ActiveRecord::Migration[8.1]
  def up
    RecordingStudioLogs::Schema.install_runs!
  end

  def down
    drop_table :recording_studio_logs_maintenance_runs, if_exists: true
    drop_table :recording_studio_logs_aggregation_runs, if_exists: true
  end
end
