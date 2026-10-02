class CreateShiftReports < ActiveRecord::Migration[8.1]
  def change
    add_column :people, :area, :string
    add_index :people, :area
    create_table :shift_reports do |t|
      t.date :date, null: false
      t.string :shift, null: false
      t.string :signer_name, null: false
      t.string :signer_email, null: false
      t.jsonb :participants, null: false, default: []
      t.text :statement, null: false
      t.datetime :sent_at
      t.timestamps
    end
  end
end
