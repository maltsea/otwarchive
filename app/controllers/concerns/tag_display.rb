module TagDisplay
  extend ActiveSupport::Concern

  # GET /tags
  def index
    if @collection
      @tags = Freeform.canonical.for_collections_with_count([@collection] + @collection.children)
      @page_subtitle = t(".collection_page_title", collection_title: @collection.title)
    else
      no_fandom = Fandom.find_by_name(ArchiveConfig.FANDOM_NO_TAG_NAME)
      if no_fandom
        @tags = no_fandom.children.by_type("Freeform").first_class.limit(ArchiveConfig.TAGS_IN_CLOUD)
        # have to put canonical at the end so that it doesn't overwrite sort order for random and popular
        # and then sort again at the very end to make it alphabetic
        @tags = if params[:show] == "random"
                  @tags.random.canonical.sort
                else
                  @tags.popular.canonical.sort
                end
      else
        @tags = []
      end
    end
  end

  def show
    @page_subtitle = @tag.name
    if @tag.is_a?(Banned) && !logged_in_as_admin?
      flash[:error] = t("admin.access.not_admin_denied")
      redirect_to(tag_wranglings_path) && return
    end
    # if tag is NOT wrangled, prepare to show works, collections, and bookmarks that are using it
    if !@tag.canonical && !@tag.merger
      @works = if logged_in? # current_user.is_a?User
                 @tag.works.visible_to_registered_user.paginate(page: params[:page])
               elsif logged_in_as_admin?
                 @tag.works.visible_to_admin.paginate(page: params[:page])
               else
                 @tag.works.visible_to_all.paginate(page: params[:page])
               end
      @bookmarks = @tag.bookmarks.visible.paginate(page: params[:page])
      @collections = @tag.collections.paginate(page: params[:page])
    end

    @has_mergers = @tag.canonical && @tag.mergers.exists?
  end

  def feed
    begin
      @tag = Tag.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      raise ActiveRecord::RecordNotFound, "Couldn't find tag with id '#{params[:id]}'"
    end
    @tag = @tag.merger if !@tag.canonical? && @tag.merger
    # Temp for testing
    if %w[Fandom Character Relationship].include?(@tag.type.to_s) || @tag.name == "F/F"
      @works = if @tag.canonical?
                 @tag.filtered_works.visible_to_all.order("created_at DESC").limit(25)
               else
                 @tag.works.visible_to_all.order("created_at DESC").limit(25)
               end
    else
      redirect_to(tag_works_path(tag_id: @tag.to_param)) && return
    end

    respond_to do |format|
      format.html
      format.atom
    end
  end

  def show_hidden
    unless params[:creation_id].blank? || params[:creation_type].blank? || params[:tag_type].blank?
      model = case params[:creation_type].downcase
              when "series"
                Series
              when "work"
                Work
              when "chapter"
                Chapter
              end
      @display_creation = model.find(params[:creation_id]) if model.is_a? Class

      # Tags aren't directly on series, so we need to handle them differently
      @display_tags = if params[:creation_type] == "Series"
                        if params[:tag_type] == "warnings"
                          @display_creation.works.visible.collect(&:archive_warnings).flatten.compact.uniq.sort
                        else
                          @display_creation.works.visible.collect(&:freeforms).flatten.compact.uniq.sort
                        end
                      else
                        case params[:tag_type]
                        when "warnings"
                          @display_creation.archive_warnings
                        when "freeforms"
                          @display_creation.freeforms
                        end
                      end

      # The string used in views/tags/show_hidden.js.erb
      @display_category = if params[:tag_type] == "warnings"
                            "warnings"
                          else
                            @display_tags.first.class.name.tableize
                          end
    end

    respond_to do |format|
      format.html do
        # This is just a quick fix to avoid script barf if JavaScript is disabled
        flash[:error] = ts("Sorry, you need to have JavaScript enabled for this.")
        redirect_back_or_to root_path
      end
      format.js
    end
  end
end
