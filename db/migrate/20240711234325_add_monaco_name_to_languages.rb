class AddMonacoNameToLanguages < ActiveRecord::Migration[7.1]
  def change
    add_column :languages, :monaco_name, :string
  end
end
