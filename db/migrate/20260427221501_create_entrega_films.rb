class CreateEntregaFilms < ActiveRecord::Migration[8.1]
  def change
    create_table :entrega_films do |t|
      t.date :fecha
      t.string :operador_bodega
      t.integer :rollos_entregados
      t.text :observaciones

      t.timestamps
    end
  end
end
