class CreateTptImportsAndEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :tpt_imports do |t|
      t.string :filename, null: false
      t.string :author_email, null: false
      t.integer :imported_count, null: false, default: 0
      t.integer :duplicate_count, null: false, default: 0
      t.integer :summary_count, null: false, default: 0
      t.jsonb :issues, null: false, default: []
      t.timestamps
    end

    create_table :tpt_events do |t|
      t.references :tpt_import, null: false, foreign_key: true
      t.integer :source_row, null: false
      t.string :impact, null: false
      t.string :production_state, null: false
      t.string :reason, null: false
      t.datetime :started_at, null: false, precision: 6
      t.decimal :duration_seconds, null: false, precision: 20, scale: 6
      t.string :source_fingerprint, null: false
      t.timestamps
    end
    add_index :tpt_events, :source_fingerprint, unique: true
    add_index :tpt_events, :started_at
  end
end
