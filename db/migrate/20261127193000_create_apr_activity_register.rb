class CreateAprActivityRegister < ActiveRecord::Migration[8.1]
  def change
    create_table :apr_days do |t|
      t.references :apr, null: false, foreign_key: { to_table: :dashboard_users }, index: false
      t.date :date, null: false
      t.string :plant, null: false
      t.datetime :closed_at
      t.string :closed_by_email
      t.string :recipients, array: true, default: [], null: false
      t.jsonb :email_summary, default: {}, null: false
      t.datetime :sent_at
      t.string :created_by_email
      t.string :updated_by_email
      t.timestamps
      t.index %i[apr_id plant date], unique: true
    end

    create_table :apr_activities do |t|
      t.references :apr_day, null: false, foreign_key: true
      t.string :sector, null: false
      t.string :activity_type, null: false
      t.string :title, null: false
      t.text :observations
      t.integer :duration_minutes, null: false
      t.string :outcome, null: false
      t.string :severity
      t.string :responsible
      t.date :due_on
      t.string :follow_up_status
      t.text :resolution
      t.datetime :resolved_at
      t.string :resolved_by_email
      t.string :created_by_email
      t.string :updated_by_email
      t.timestamps
      t.check_constraint "duration_minutes BETWEEN 1 AND 1440", name: "apr_activities_valid_duration"
    end
  end
end
