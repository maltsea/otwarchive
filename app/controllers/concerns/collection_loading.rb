module CollectionLoading
  extend ActiveSupport::Concern

  def load_collection
    @collection = Collection.find_by(name: params[:collection_id]) if params[:collection_id]
  end

  def load_collection_from_id
    @collection = Collection.find_by(name: params[:id])
    raise ActiveRecord::RecordNotFound, "Couldn't find collection named '#{params[:id]}'" unless @collection
  end

  def check_parent_visible
    return unless params[:work_id] && (@work = Work.find_by(id: params[:work_id]))

    check_visibility_for(@work)
  end
end
