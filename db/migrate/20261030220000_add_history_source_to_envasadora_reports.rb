class AddHistorySourceToEnvasadoraReports < ActiveRecord::Migration[8.1]
  def change
    add_column :envasadora_reports, :source_filename, :string
    add_column :envasadora_reports, :source_row, :integer
    add_column :envasadora_reports, :source_fingerprint, :string
    add_column :envasadora_reports, :source_data, :jsonb, null: false, default: {}
    add_index :envasadora_reports, :source_fingerprint, unique: true
  end
end
