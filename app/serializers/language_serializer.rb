class LanguageSerializer < ActiveModel::Serializer
  attributes :id, :name, :monaco_name, :major, :minor, :patch
end
