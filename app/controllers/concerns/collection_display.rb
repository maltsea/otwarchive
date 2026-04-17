module CollectionDisplay
  extend ActiveSupport::Concern

  def index
    if params[:work_id]
      @work = Work.find(params[:work_id])
      @collections = @work.approved_collections
        .by_title
        .for_blurb
        .paginate(page: params[:page])
    elsif params[:collection_id]
      @collection = Collection.find_by!(name: params[:collection_id])
      @search = CollectionSearchForm.new({ parent_id: @collection.id, sort_column: "title.keyword" }.merge(page: params[:page]))
      @collections = @search.search_results.scope(:for_search)
      flash_search_warnings(@collections)
      @page_subtitle = t(".subcollections_page_title", collection_title: @collection.title)
    elsif params[:user_id]
      @user = User.find_by!(login: params[:user_id])
      @search = CollectionSearchForm.new({ maintainer_id: @user.id, sort_column: "title.keyword" }.merge(page: params[:page]))
      @collections = @search.search_results.scope(:for_search)
      flash_search_warnings(@collections)
      @page_subtitle = ts("%{username} - Collections", username: @user.login)
    else
      @sort_and_filter = true
      @search = CollectionSearchForm.new(collection_filter_params.merge(page: params[:page]))
      @collections = @search.search_results.scope(:for_search)
      flash_search_warnings(@collections)
    end
  end

  def show
    @page_subtitle = @collection.title

    if @collection.collection_preference.show_random? || params[:show_random]
      # show a random selection of works/bookmarks
      @works = WorkQuery.new(
        collection_ids: [@collection.id], show_restricted: is_registered_user?
      ).sample(count: ArchiveConfig.NUMBER_OF_ITEMS_VISIBLE_IN_DASHBOARD)

      @bookmarks = BookmarkQuery.new(
        collection_ids: [@collection.id], show_restricted: is_registered_user?
      ).sample(count: ArchiveConfig.NUMBER_OF_ITEMS_VISIBLE_IN_DASHBOARD)
    else
      # show recent
      @works = WorkQuery.new(
        collection_ids: [@collection.id], show_restricted: is_registered_user?,
        sort_column: "revised_at",
        per_page: ArchiveConfig.NUMBER_OF_ITEMS_VISIBLE_IN_DASHBOARD
      ).search_results

      @bookmarks = BookmarkQuery.new(
        collection_ids: [@collection.id], show_restricted: is_registered_user?,
        sort_column: "created_at",
        per_page: ArchiveConfig.NUMBER_OF_ITEMS_VISIBLE_IN_DASHBOARD
      ).search_results
    end
  end
end
