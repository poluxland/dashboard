class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.string :assignee_email, null: false
      t.string :creator_email, null: false
      t.date :due_on
      t.string :status, null: false, default: "pending"
      t.string :priority, null: false, default: "normal"
      t.timestamps
    end
    add_index :tasks, [ :assignee_email, :status, :due_on ]
  end
end
