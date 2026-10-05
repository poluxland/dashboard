class AddShiftReportEnabledToPeople < ActiveRecord::Migration[8.1]
  def change
    add_column :people, :shift_report_enabled, :boolean, default: true, null: false
  end
end
