class PrefixNumericMantencionAreas < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE mantenciones
      SET area = 'P' || area
      WHERE area ~ '^[0-9]{3}'
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "No se pueden distinguir las áreas corregidas de las que ya tenían P."
  end
end
