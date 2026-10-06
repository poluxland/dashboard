class AddObservationsToShiftReports < ActiveRecord::Migration[8.1]
  def change
    add_column :shift_reports, :observations, :text
  end
end
