class AddActivityDetailsToAprHistoryEntries < ActiveRecord::Migration[8.1]
  def change
    add_column :apr_history_entries, :activity_details, :jsonb, default: {}, null: false
  end
end
