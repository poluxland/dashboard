class AddTechnicalReportFieldsToWorks < ActiveRecord::Migration[8.1]
  def change
    add_column :works, :area, :string
    add_column :works, :tag, :string
    add_column :works, :repuestos, :text
    add_column :works, :epp, :text
    add_column :works, :hallazgos, :text
    add_column :works, :observaciones, :text
  end
end
