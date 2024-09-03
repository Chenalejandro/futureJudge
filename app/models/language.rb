class Language < ApplicationRecord
  validates :name, :monaco_name, :source_file, :run_cmd, :major, :minor, :patch, presence: true

  has_many(:submissions)
end
