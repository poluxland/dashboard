class CreateTrabajos < ActiveRecord::Migration[8.1]
  def change
    create_table :trabajos do |t|
      t.bigint :erp_id
      t.string :author_email
      t.string :planta
      t.string :ito
      t.string :descripcion
      t.bigint :total, default: 0
      t.date :fecha_termino
      t.string :avance
      t.integer :op
      t.integer :factura
      t.text :observaciones
      t.string :centro_costo
      t.string :supervisor
      t.text :otros
      t.text :detalle

      (1..12).each do |number|
        t.string "i#{number}"
        t.integer "q#{number}"
        t.integer "v#{number}"
      end

      t.timestamps
      t.index :erp_id, unique: true
      t.index :author_email
      t.index [ :avance, :planta, :fecha_termino ]
    end
  end
end
