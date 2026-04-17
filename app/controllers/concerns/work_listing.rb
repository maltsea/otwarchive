module WorkListing
  extend ActiveSupport::Concern

  def search
    @languages = Language.default_order
    options = params[:work_search].present? ? clean_work_search_params : {}
    options[:page] = params[:page] if params[:page].present?
    options[:show_restricted] = current_user.present? || logged_in_as_admin?
    @search = WorkSearchForm.new(options)
    @page_subtitle = ts("Search Works")

    return unless params[:work_search].present? && params[:edit_search].blank?

    @page_subtitle = ts("Works Matching '%{query}'", query: @search.query) if @search.query.present?

    @works = @search.search_results.scope(:for_blurb)
    set_own_works
    flash_search_warnings(@works)
    render "search_results"
  end

  def index
    base_options = {
      page: params[:page] || 1,
      show_restricted: current_user.present? || logged_in_as_admin?
    }

    options = params[:work_search].present? ? clean_work_search_params : {}

    if params[:fandom_id].present? || (@collection.present? && @tag.present?)
      @fandom = Fandom.find(params[:fandom_id]) if params[:fandom_id]

      tag = @fandom || @tag
      options[:filter_ids] ||= []
      options[:filter_ids] << tag.id
    end

    if params[:include_work_search].present?
      params[:include_work_search].each_key do |key|
        options[key] ||= []
        options[key] << params[:include_work_search][key]
        options[key].flatten!
      end
    end

    if params[:exclude_work_search].present?
      params[:exclude_work_search].each_key do |key|
        options[:excluded_tag_ids] ||= []
        options[:excluded_tag_ids] << params[:exclude_work_search][key]
        options[:excluded_tag_ids].flatten!
      end
    end

    options.merge!(base_options)
    @page_subtitle = index_page_title

    if logged_in? && @tag
      @favorite_tag = @current_user.favorite_tags.where(tag_id: @tag.id).first ||
                      FavoriteTag.new(tag_id: @tag.id, user_id: @current_user.id)
    end

    if @owner.present?
      @search = WorkSearchForm.new(options.merge(faceted: true, works_parent: @owner))

      if use_caching? && params[:work_search].blank? && params[:fandom_id].blank? &&
         params[:include_work_search].blank? && params[:exclude_work_search].blank? &&
         (params[:page].blank? || params[:page].to_i <= ArchiveConfig.PAGES_TO_CACHE)
        subtag = @tag.present? && @tag != @owner ? @tag : nil
        user = logged_in? || logged_in_as_admin? ? "logged_in" : "logged_out"
        @works = Rails.cache.fetch("#{@owner.works_index_cache_key(subtag)}_#{user}_page#{params[:page]}_v1", expires_in: ArchiveConfig.SECONDS_UNTIL_WORK_INDEX_EXPIRE.seconds) do
          results = @search.search_results.scope(:for_blurb)
          results.items
          results.facets
          results
        end
      else
        @works = @search.search_results.scope(:for_blurb)
      end

      flash_search_warnings(@works)
      @facets = @works.facets

      if @search.options[:excluded_tag_ids].present? && @facets
        tags = Tag.where(id: @search.options[:excluded_tag_ids])
        tags.each do |tag|
          @facets[tag.class.to_s.underscore] ||= []
          @facets[tag.class.to_s.underscore] << QueryFacet.new(tag.id, tag.name, 0)
        end
      end
    elsif use_caching?
      @works = Rails.cache.fetch("works/index/latest/v2", expires_in: ArchiveConfig.SECONDS_UNTIL_WORK_INDEX_EXPIRE.seconds) do
        Work.latest.for_blurb.to_a
      end
    else
      @works = Work.latest.for_blurb.to_a
    end

    set_own_works
    @pagy = pagy_query_result(@works) if @works.respond_to?(:total_pages)
  end

  def collected
    options = params[:work_search].present? ? clean_work_search_params : {}
    options[:page] = params[:page] || 1
    options[:show_restricted] = current_user.present? || logged_in_as_admin?

    @user = User.find_by!(login: params[:user_id])
    @search = WorkSearchForm.new(options.merge(works_parent: @user, collected: true))
    @works = @search.search_results.scope(:for_blurb)
    flash_search_warnings(@works)
    @facets = @works.facets
    set_own_works
    @page_subtitle = ts("%{username} - Collected Works", username: @user.login)
  end

  def drafts
    unless params[:user_id] && (@user = User.find_by(login: params[:user_id]))
      flash[:error] = ts("Whose drafts did you want to look at?")
      redirect_to users_path
      return
    end

    unless current_user == @user || logged_in_as_admin?
      flash[:error] = ts("You can only see your own drafts, sorry!")
      redirect_to logged_in? ? user_path(current_user) : new_user_session_path(return_to: request.fullpath)
      return
    end

    @page_subtitle = t(".page_title", username: @user.login)

    if params[:pseud_id]
      @pseud = @user.pseuds.find_by(name: params[:pseud_id])
      @works = @pseud.unposted_works.for_blurb.paginate(page: params[:page])
    else
      @works = @user.unposted_works.for_blurb.paginate(page: params[:page])
    end
  end
end
