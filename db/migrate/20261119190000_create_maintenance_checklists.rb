class CreateMaintenanceChecklists < ActiveRecord::Migration[8.0]
  def change
    create_table :maintenance_checklists do |t|
      t.bigint :erp_id, index: { unique: true }
      t.references :mobile_asset, foreign_key: true
      t.string :legacy_code
      t.string :technician
      t.string :operating_status
      t.string :hour_meter
      (1..19).each { |number| t.boolean :"c#{number}", default: false }
      %i[fuel engine_oil hydraulic_oil transmission_oil atf_oil nuto_oil].each { |field| t.integer field }
      t.timestamps
      t.index [ :created_at, :id ]
    end
  end
end
