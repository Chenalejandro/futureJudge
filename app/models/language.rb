class Language < ApplicationRecord
  validates :name, :monaco_name, :source_file, :run_cmd, presence: true

  has_many(:submissions)
end
