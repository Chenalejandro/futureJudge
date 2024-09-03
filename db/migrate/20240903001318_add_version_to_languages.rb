class AddVersionToLanguages < ActiveRecord::Migration[7.2]
  def change
    add_column :languages, :major, :integer, null: false
    add_column :languages, :minor, :integer, null: false
    add_column :languages, :patch, :integer, null: false
  end
end
