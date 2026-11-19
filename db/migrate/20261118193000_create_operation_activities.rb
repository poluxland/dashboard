class CreateOperationActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :operation_activities do |t|
      t.date :fecha, null: false, index: true
      t.string :area, null: false
      t.text :actividad, null: false
      t.string :tipo, null: false
      t.decimal :estado, precision: 5, scale: 2, null: false
      t.timestamps

      t.check_constraint "estado BETWEEN 0 AND 100", name: "operation_activities_estado_range"
    end
  end
end
