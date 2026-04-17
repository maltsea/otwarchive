module TagLoading
  extend ActiveSupport::Concern

  def load_tag
    @tag = Tag.find_by_name!(params[:id])
  end
end
