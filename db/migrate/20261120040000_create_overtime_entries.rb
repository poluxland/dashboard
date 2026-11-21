class CreateOvertimeEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :overtime_entries do |t|
      t.bigint :erp_id
      t.datetime :erp_updated_at
      t.date :fecha
      t.string :descripcion
      t.string :area
      t.string :personal
      t.time :inicio
      t.time :termino
      t.float :he
      t.integer :ot
      t.string :traslado
      t.string :lugar
      t.string :mandante
      t.string :estado
      t.string :ep
      t.string :author_email
      t.timestamps
      t.index :erp_id, unique: true
      t.index [:estado, :mandante, :fecha]
    end

    create_table :overtime_reviews do |t|
      t.references :overtime_entry, null: false, foreign_key: true
      t.string :reviewer_email, null: false
      t.string :previous_status, null: false
      t.string :status, null: false
      t.text :reason
      t.datetime :created_at, null: false
    end

    create_table :overtime_login_codes do |t|
      t.string :email, null: false, index: { unique: true }
      t.string :challenge, null: false
      t.string :digest, null: false
      t.integer :attempts, null: false, default: 0
      t.datetime :issued_at, null: false
      t.datetime :used_at
    end

    create_table :overtime_report_deliveries do |t|
      t.datetime :scheduled_at, null: false
      t.string :recipient, null: false
      t.datetime :sent_at
      t.index [:scheduled_at, :recipient], unique: true
    end
  end
end
