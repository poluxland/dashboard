class AddSourceFingerprintToMantenciones < ActiveRecord::Migration[8.1]
  def change
    add_column :mantenciones, :source_fingerprint, :string
    add_index :mantenciones, :source_fingerprint, unique: true
  end
end
