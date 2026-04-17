module TagForm
  extend ActiveSupport::Concern

  # GET /tags/new
  def new
    authorize :wrangling if logged_in_as_admin?

    @tag = Tag.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # POST /tags
  def create
    type = tag_params[:type] if params[:tag]

    unless type
      flash[:error] = ts("Please provide a category.")
      @tag = Tag.new(name: tag_params[:name])
      render(action: "new")
      return
    end

    raise "Redshirt: Attempted to constantize invalid class initialize create #{type.classify}" unless Tag::TYPES.include?(type.classify)

    model = begin
      type.classify.constantize
    rescue StandardError
      nil
    end
    @tag = model.find_or_create_by_name(tag_params[:name]) if model.is_a? Class

    unless @tag&.valid?
      render(action: "new")
      return
    end

    if @tag.id_previously_changed? # i.e. tag is new
      @tag.update_attribute(:canonical, tag_params[:canonical])
      flash[:notice] = ts("Tag was successfully created.")
    else
      flash[:notice] = ts("Tag already existed and was not modified.")
    end

    redirect_to edit_tag_path(@tag)
  end

  def edit
    authorize :wrangling, :read_access? if logged_in_as_admin?

    @page_subtitle = ts("%{tag_name} - Edit", tag_name: @tag.name)

    if @tag.is_a?(Banned) && !logged_in_as_admin?
      flash[:error] = ts("Please log in as admin")

      redirect_to(tag_wranglings_path) && return
    end

    @counts = {}
    @uses = ["Works", "Drafts", "Bookmarks", "Private Bookmarks", "External Works", "Collections", "Taggings Count"]
    @counts["Works"] = @tag.visible_works_count
    @counts["Drafts"] = @tag.works.unposted.count
    @counts["Bookmarks"] = @tag.visible_bookmarks_count
    @counts["Private Bookmarks"] = @tag.bookmarks.not_public.count
    @counts["External Works"] = @tag.visible_external_works_count
    @counts["Collections"] = @tag.collections.count
    @counts["Taggings Count"] = @tag.taggings_count

    @parents = @tag.parents.order(:name).group_by { |tag| tag[:type] }
    @parents["MetaTag"] = @tag.direct_meta_tags.by_name
    @children = @tag.children.order(:name).group_by { |tag| tag[:type] }
    @children["SubTag"] = @tag.direct_sub_tags.by_name
    @children["Merger"] = @tag.mergers.by_name

    if @tag.respond_to?(:wranglers)
      @wranglers = if @tag.canonical
                     @tag.wranglers
                   else
                     (@tag.merger ? @tag.merger.wranglers : [])
                   end
    elsif @tag.respond_to?(:fandoms) && !@tag.fandoms.empty?
      @wranglers = @tag.fandoms.collect(&:wranglers).flatten.uniq
    end
    @suggested_fandoms = @tag.suggested_parent_tags("Fandom") - @tag.fandoms if @tag.respond_to?(:fandoms)
  end

  def update
    authorize :wrangling if logged_in_as_admin?

    # update everything except for the synonym,
    # so that the associations are there to move when the synonym is created
    syn_string = params[:tag].delete(:syn_string)
    new_tag_type = params[:tag].delete(:type)

    # Limiting the conditions under which you can update the tag type
    types = logged_in_as_admin? ? (Tag::USER_DEFINED + %w[Media]) : Tag::USER_DEFINED
    @tag = @tag.recategorize(new_tag_type) if @tag.can_change_type? && (types + %w[UnsortedTag]).include?(new_tag_type)

    @tag.attributes = tag_params unless params[:tag].empty?

    @tag.syn_string = syn_string if @tag.errors.empty? && @tag.save

    if @tag.errors.empty? && @tag.save
      flash[:notice] = ts("Tag was updated.")
      redirect_to edit_tag_path(@tag)
    else
      @parents = @tag.parents.order(:name).group_by { |tag| tag[:type] }
      @parents["MetaTag"] = @tag.direct_meta_tags.by_name
      @children = @tag.children.order(:name).group_by { |tag| tag[:type] }
      @children["SubTag"] = @tag.direct_sub_tags.by_name
      @children["Merger"] = @tag.mergers.by_name

      render :edit
    end
  end
end
