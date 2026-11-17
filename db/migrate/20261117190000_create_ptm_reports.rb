class CreatePtmReports < ActiveRecord::Migration[8.1]
  def change
    create_table :ptm_reports do |t|
      t.date :date, null: false
      t.string :shift, null: false
      t.integer :production
      t.string :author_email, null: false
      t.string :source_key
      t.jsonb :source_rows, default: [], null: false
      t.text :review_notes
      t.timestamps
    end
    add_index :ptm_reports, [ :date, :shift ], unique: true
    add_index :ptm_reports, :source_key, unique: true
    create_table :ptm_events do |t|
      t.references :ptm_report, null: false, foreign_key: true
      t.string :equipment, null: false
      t.string :original_equipment
      t.text :reason
      t.decimal :minutes, precision: 10, scale: 2
      t.string :equipment_state
      t.integer :source_row
      t.timestamps
    end
  end
end
