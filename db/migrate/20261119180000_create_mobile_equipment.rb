class CreateMobileEquipment < ActiveRecord::Migration[8.0]
  def change
    create_table :mobile_assets do |t|
      t.bigint :erp_id, index: { unique: true }
      t.string :code
      t.string :brand
      t.string :model
      t.string :plant
      t.integer :year
      t.text :notes
      t.timestamps
    end

    create_table :equipment_checklists do |t|
      t.bigint :erp_id, index: { unique: true }
      t.references :mobile_asset, foreign_key: true
      t.string :legacy_code
      t.string :operator
      t.integer :hour_meter
      (1..30).each { |number| t.string :"c#{number}" }
      t.text :comments
      t.timestamps
      t.index [ :created_at, :id ]
    end
  end
end
