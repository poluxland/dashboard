class RemoveMaintenanceChecklistAnswerDefaults < ActiveRecord::Migration[8.0]
  def change
    (1..19).each do |number|
      change_column_default :maintenance_checklists, :"c#{number}", from: false, to: nil
    end
  end
end
