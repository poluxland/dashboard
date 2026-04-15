class CreateEstadoEquipos < ActiveRecord::Migration[8.1]
  def change
    create_table :estado_equipos do |t|
      t.string :equipo_principal
      t.string :equipo
      t.integer :estado_cinta
      t.integer :estado_motor
      t.integer :estado_polines
      t.integer :estado_ruedas
      t.integer :estado_capachos
      t.integer :estado_sistema_aire
      t.integer :estado_filtro
      t.integer :estado_estructura
      t.integer :estado_lubricacion
      t.integer :estado_limpieza
      t.text :comentarios

      t.timestamps
    end
  end
end
