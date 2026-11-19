class CreateHaverDailyDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :haver_daily_deliveries do |t|
      t.date :scheduled_on, null: false
      t.datetime :sent_at
      t.timestamps
      t.index :scheduled_on, unique: true
    end
  end
end
