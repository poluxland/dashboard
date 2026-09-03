class CreateMantenciones < ActiveRecord::Migration[8.1]
  def change
    create_table :mantenciones do |t|
      t.integer :semana
      t.date :fecha
      t.string :especialidad, default: "Eléctrico", null: false
      t.string :area
      t.string :codigo
      t.string :tipo_mantencion
      t.text :actividad
      t.string :planificacion
      t.decimal :estado, precision: 5, scale: 2
      t.string :numero_ot
      t.decimal :duracion, precision: 8, scale: 2
      t.text :comentarios

      t.timestamps
    end

    add_index :mantenciones, :fecha
    add_index :mantenciones, :numero_ot
    add_index :mantenciones, :especialidad
  end
end
