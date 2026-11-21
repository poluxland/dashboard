class CreatePmmTruckRegister < ActiveRecord::Migration[8.1]
  def change
    create_table :pmm_materials do |t|
      t.bigint :pmm_id, index: { unique: true }
      t.datetime :pmm_updated_at
      t.string :nombre
      t.string :descripcion
      t.integer :densidad
      t.timestamps
    end

    create_table :pmm_yards do |t|
      t.bigint :pmm_id, index: { unique: true }
      t.datetime :pmm_updated_at
      t.references :pmm_material, null: false, foreign_key: true
      t.string :nombre
      t.string :descripcion
      t.integer :capacidad
      t.boolean :operativa
      t.timestamps
    end

    create_table :pmm_trucks do |t|
      t.bigint :pmm_id, index: { unique: true }
      t.datetime :pmm_updated_at
      t.references :pmm_material, null: false, foreign_key: true
      t.date :fecha, index: true
      t.string :tipo
      t.time :llegada
      t.time :llamada
      t.time :salida
      t.string :patente
      t.integer :wait
      t.string :cause
      t.text :motive
      t.integer :number
      t.string :other
      t.boolean :finished
      t.timestamps
      t.index [ :pmm_material_id, :fecha ]
      t.index [ :created_at, :id ]
    end

    create_table :pmm_bru_visits do |t|
      t.bigint :pmm_id, null: false, index: { unique: true }
      t.datetime :pmm_updated_at
      t.date :fecha, index: true
      t.time :ingreso
      t.time :salida
      t.string :patente
      t.string :mmpp
      t.string :comentarios
      t.integer :numero
      t.timestamps
    end
  end
end
