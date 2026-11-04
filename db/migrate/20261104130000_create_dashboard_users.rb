class CreateDashboardUsers < ActiveRecord::Migration[8.1]
  def up
    create_table :dashboard_users do |t|
      t.string :email, null: false
      t.string :name
      t.timestamps
    end
    add_index :dashboard_users, :email, unique: true
    execute <<~SQL
      INSERT INTO dashboard_users (email, created_at, updated_at)
      SELECT DISTINCT lower(trim(email)), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM (
        SELECT assignee_email AS email FROM tasks
        UNION SELECT creator_email FROM tasks
        UNION SELECT author_email FROM envasadora_reports
        UNION SELECT author_email FROM tpt_imports
        UNION SELECT signer_email FROM shift_reports
        UNION SELECT 'jose.jerez@msindustrial.cl'
        UNION SELECT 'fernando.gonzalez@msindustrial.cl'
      ) known_users
      WHERE lower(trim(email)) ~ '^[^[:space:]@]+@msindustrial[.]cl$'
      ON CONFLICT (email) DO NOTHING
    SQL
  end

  def down
    drop_table :dashboard_users
  end
end
