class CreateIndicatorReadings < ActiveRecord::Migration[8.0]
  def change
    create_table :indicator_readings do |t|
      t.references :person, null: false, foreign_key: true
      t.date :period, null: false

      t.decimal :cuasi, precision: 5, scale: 2, null: false, default: 0
      t.decimal :lvs,   precision: 5, scale: 2, null: false, default: 0
      t.decimal :cc,    precision: 5, scale: 2, null: false, default: 0
      t.decimal :hh,    precision: 5, scale: 2, null: false, default: 0

      t.timestamps
    end

    # Para que una persona solo tenga un registro por mes
    add_index :indicator_readings, [ :person_id, :period ],
              unique: true, name: "idx_unique_person_period"
  end
end
