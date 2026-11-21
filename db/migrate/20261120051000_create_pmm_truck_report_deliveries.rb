class CreatePmmTruckReportDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :pmm_truck_report_deliveries do |t|
      t.datetime :scheduled_at, null: false, index: { unique: true }
      t.datetime :sent_at
    end
  end
end
