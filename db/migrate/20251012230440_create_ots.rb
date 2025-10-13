class CreateOts < ActiveRecord::Migration[8.0]
  def change
    create_table :ots do |t|
      t.integer :semana
      t.integer :item
      t.string :area
      t.string :codigo
      t.string :actividad_semanal
      t.string :esp
      t.integer :frecuencia
      t.integer :cod_rep
      t.integer :cantidad
      t.integer :unitario
      t.integer :servicio
      t.integer :cotizacion
      t.string :cc
      t.string :responsable
      t.string :contratista
      t.string :tipo_ot
      t.integer :estado
      t.integer :sem_ejec
      t.integer :n_personas
      t.integer :duracion_hr
      t.integer :hh
      t.string :causa
      t.text :comentarios

      t.timestamps
    end
  end
end
