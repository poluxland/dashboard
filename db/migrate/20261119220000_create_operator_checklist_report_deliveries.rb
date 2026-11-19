class CreateOperatorChecklistReportDeliveries < ActiveRecord::Migration[8.0]
  def change
    create_table :operator_checklist_report_deliveries do |t|
      t.string :plant, null: false
      t.datetime :scheduled_at, null: false
      t.datetime :sent_at
      t.timestamps
      t.index [ :plant, :scheduled_at ], unique: true
    end
  end
end
