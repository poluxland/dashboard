class AddVentoQualityCountsToEnvasadoraReports < ActiveRecord::Migration[8.1]
  def change
    add_column :envasadora_reports, :sacos_no_reconocidos_vento, :integer
    add_column :envasadora_reports, :sacos_descartados_vento, :integer
  end
end
