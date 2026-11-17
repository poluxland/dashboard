class AddHistoryAdjustmentsToPtmReports < ActiveRecord::Migration[8.1]
  def change
    add_column :ptm_reports, :history_adjustments, :jsonb, default: {}, null: false
  end
end
