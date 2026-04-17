module WorkLoading
  extend ActiveSupport::Concern

  included do
    # nothing to include for now
  end

  private

  def load_owner
    if params[:user_id].present?
      @user = User.find_by!(login: params[:user_id])
      @pseud = @user.pseuds.find_by(name: params[:pseud_id]) if params[:pseud_id].present?
    end

    if params[:tag_id]
      @tag = Tag.find_by_name(params[:tag_id])
      raise ActiveRecord::RecordNotFound, "Couldn't find tag named '#{params[:tag_id]}'" unless @tag && @tag.is_a?(Tag)

      unless @tag.canonical?
        if @collection.present?
          redirect_to(collection_tag_works_path(@collection, @tag.merger)) && return
        else
          redirect_to(tag_works_path(@tag.merger)) && return
        end
      end
    end

    @language = Language.find_by(short: params[:language_id]) if params[:language_id].present?
    @owner = @pseud || @user || @collection || @tag || @language
  end

  def load_work
    @work = Work.find_by(id: params[:id])
    raise ActiveRecord::RecordNotFound, "Couldn't find work with id '#{params[:id]}'" unless @work

    redirect_to(@work) && return if @collection && !@work.collections.include?(@collection)

    @check_ownership_of = @work
    @check_visibility_of = @work
  end

  def check_parent_visible
    check_visibility_for(@work)
  end

  def load_first_chapter
    @chapter = if @work.user_is_owner_or_invited?(current_user) || logged_in_as_admin?
                 @work.first_chapter
               else
                 @work.chapters.in_order.posted.first
               end
  end

  def set_work_form_fields
    @work.reset_published_at(@chapter)
    @series = current_user.series.distinct
    @serial_works = @work.serial_works

    @collection = @work.approved_collections.first if @collection.nil?
    @posting_claim = ChallengeClaim.find_by(id: params[:claim_id]) if params[:claim_id]
  end

  def set_own_works
    return unless @works

    @own_works = []
    if current_user.is_a?(User)
      pseud_ids = current_user.pseuds.pluck(:id)
      @own_works = @works.select do |work|
        (pseud_ids & work.pseuds.pluck(:id)).present?
      end
    end
  end

  def index_page_title
    if @owner.present?
      owner_name =
        case @owner.class.to_s
        when "Pseud"
          @owner.name
        when "User"
          @owner.login
        when "Collection"
          @owner.title
        else
          @owner.try(:name)
        end

      "#{owner_name} - Works".html_safe
    else
      "Latest Works"
    end
  end

  def log_admin_activity
    return unless logged_in_as_admin?

    options = { action: params[:action] }
    summary = "Old tags: #{@work.tags.pluck(:name).join(', ')}" if params[:action] == "update_tags"

    AdminActivity.log_action(current_admin, @work, action: params[:action], summary: summary)
  end
end
