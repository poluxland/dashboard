class EnhanceTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :category, :string, null: false, default: "other"
    add_column :tasks, :plant, :string, null: false, default: "N/A"
    create_table :task_items do |t|
      t.references :task, null: false, foreign_key: true
      t.string :title, null: false
      t.date :due_on, null: false
      t.boolean :completed, null: false, default: false
      t.timestamps
    end
    create_table :task_notifications do |t|
      t.references :task, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :recipient, null: false
      t.date :due_on
      t.string :deduplication_key, null: false
      t.datetime :sent_at
      t.timestamps
    end
    add_index :task_notifications, :deduplication_key, unique: true
  end
end
