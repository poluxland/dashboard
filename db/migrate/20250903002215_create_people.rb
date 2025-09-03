class CreatePeople < ActiveRecord::Migration[8.0]
  def change
    create_table :people do |t|
      t.string :name

      t.timestamps
    end
    add_index :people, :name, unique: true
  end
end
