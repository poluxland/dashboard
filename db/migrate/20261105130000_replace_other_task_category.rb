class ReplaceOtherTaskCategory < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE tasks SET category = 'operations' WHERE category = 'other'"
    change_column_default :tasks, :category, from: "other", to: "operations"
    add_check_constraint :tasks, "category IN ('safety', 'people', 'operations')", name: "tasks_category_allowed"
  end

  def down
    remove_check_constraint :tasks, name: "tasks_category_allowed"
    change_column_default :tasks, :category, from: "operations", to: "other"
  end
end
