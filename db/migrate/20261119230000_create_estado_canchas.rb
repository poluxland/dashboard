class CreateEstadoCanchas < ActiveRecord::Migration[8.0]
  def change
    create_table :estado_canchas do |t|
      t.bigint :pmm_id, index: { unique: true }
      %i[quilimari cachinales ñilhue caolin fierro puzolana tunga ceniza yeso conchuela san_pedro
        clinker_a clinker_b clinker_importado].each do |field|
        t.integer field
      end
      t.text :observaciones
      t.timestamps
      t.index [ :created_at, :id ]
    end
  end
end
