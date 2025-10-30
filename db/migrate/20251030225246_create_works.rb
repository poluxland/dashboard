class CreateWorks < ActiveRecord::Migration[8.1]
  def change
    create_table :works do |t|
      t.date :fecha
      t.string :planta
      t.integer :numero_cotizacion
      t.string :solicita
      t.string :supervisor
      t.time :hora_inicio
      t.time :hora_termino
      t.string :nombre
      t.text :seguridad
      t.text :descripcion
      t.text :personal

      t.timestamps
    end
  end
end
