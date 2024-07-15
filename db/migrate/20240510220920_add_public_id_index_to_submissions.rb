class AddPublicIdIndexToSubmissions < ActiveRecord::Migration[7.1]
  def change
    add_index :submissions, :public_id, unique: true
  end
end
