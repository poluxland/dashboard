class ChangeCodRepToStringInOts < ActiveRecord::Migration[7.1]
  def up
    # En Postgres puedes ser explícito con USING, pero para int->string no es necesario.
    change_column :ots, :cod_rep, :string
  end

  def down
    # Rollback a integer (ojo: fallará si hay valores no numéricos)
    change_column :ots, :cod_rep, :integer, using: 'cod_rep::integer'
  end
end
