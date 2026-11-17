class CreateClinkerTransfers < ActiveRecord::Migration[8.1]
  def change
    create_table :clinker_transfers do |t|
      t.date :date, null: false
      t.decimal :tons, precision: 14, scale: 3, null: false
      t.text :observations
      t.string :author_email, null: false
      t.timestamps
    end
    add_index :clinker_transfers, :date, unique: true
  end
end
