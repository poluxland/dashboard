class AddHaverQualityCountsToEnvasadoraReports < ActiveRecord::Migration[8.1]
  def change
    add_column :envasadora_reports, :sacos_no_reconocidos_haver, :integer
    add_column :envasadora_reports, :sacos_descartados_haver, :integer
  end
end
