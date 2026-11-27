class CreateAprWeeklyDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :apr_weekly_deliveries do |t|
      t.date :week_start, null: false
      t.datetime :sent_at
      t.string :recipients, array: true, default: [], null: false
      t.timestamps
      t.index :week_start, unique: true
    end
  end
end
