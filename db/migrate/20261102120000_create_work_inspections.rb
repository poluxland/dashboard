class CreateWorkInspections < ActiveRecord::Migration[8.1]
  def change
    create_table :work_inspections do |t|
      t.references :work, null: false, foreign_key: true
      t.string :template_key, null: false
      t.string :title, null: false
      t.boolean :enabled, default: true, null: false
      t.timestamps
      t.index [ :work_id, :template_key ], unique: true
    end

    create_table :work_inspection_items do |t|
      t.references :work_inspection, null: false, foreign_key: true
      t.integer :position, null: false
      t.text :question, null: false
      t.string :answer
      t.text :observations
      t.timestamps
      t.index [ :work_inspection_id, :position ], unique: true
    end
  end
end
