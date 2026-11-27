class CreateAprHistoryEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :apr_history_entries do |t|
      t.date :date, null: false
      t.date :end_date, null: false
      t.string :plant, null: false
      t.string :day_status
      t.text :source_area
      t.text :source_date, null: false
      t.text :source_activity
      t.text :observations
      t.text :activities, array: true, default: [], null: false
      t.string :source_file, null: false
      t.string :source_sheet, null: false
      t.integer :source_row, null: false
      t.integer :source_end_row, null: false
      t.string :source_fingerprint, null: false
      t.timestamps
      t.index %i[source_file source_sheet source_row], unique: true, name: "index_apr_history_entries_on_source"
      t.index %i[plant date]
      t.check_constraint "end_date >= date", name: "apr_history_entries_valid_date_range"
    end
  end
end
