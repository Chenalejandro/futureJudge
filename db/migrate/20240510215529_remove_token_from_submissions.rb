class RemoveTokenFromSubmissions < ActiveRecord::Migration[7.1]
  def change
    remove_column :submissions, :token, :string
  end
end
