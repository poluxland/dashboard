class CreateOperationWeeklyDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :operation_weekly_deliveries do |t|
      t.date :week_start, null: false, index: { unique: true }
      t.datetime :sent_at
      t.timestamps
    end
  end
end
