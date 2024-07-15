class AddPublicIdToSubmissions < ActiveRecord::Migration[7.1]
  def change
    add_column :submissions, :public_id, :string, limit: 12
  end
end
