class AddBrokenBagsToEnvasadoraReports < ActiveRecord::Migration[8.1]
  def change
    add_column :envasadora_reports, :sacos_rotos_haver, :integer
    add_column :envasadora_reports, :sacos_rotos_vento, :integer
    add_column :envasadora_reports, :bigbags_rotos, :integer
  end
end
