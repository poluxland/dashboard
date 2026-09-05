class CompleteMantencionStatesFromWorkEvidence < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE mantenciones
      SET estado = 100
      WHERE estado IS NULL
        AND (
          LENGTH(BTRIM(comentarios)) > 0
          OR duracion > 0
        )
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "No es posible distinguir los estados completados por esta migración."
  end
end
