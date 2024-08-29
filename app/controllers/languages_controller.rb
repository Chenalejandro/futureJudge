class LanguagesController < ApplicationController
  def index
    render json: Language.all, each_serializer: LanguageSerializer, fields: [:id, :name, :monaco_name]
  end

  def show
    render json: Language.find(params[:id])
  end
end