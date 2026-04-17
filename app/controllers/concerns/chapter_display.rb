module ChapterDisplay
  extend ActiveSupport::Concern

  def index
    redirect_to work_path(params[:work_id])
  end

  def manage
    @chapters = @work.chapters_in_order(include_content: false,
                                        include_drafts: true)
  end

  def show
    redirect_to url_for(controller: :chapters, action: :show, work_id: @work.id, id: params[:selected_id]) and return if params[:selected_id]

    @chapters = @work.chapters_in_order(
      include_content: false,
      include_drafts: (logged_in_as_admin? ||
                       @work.user_is_owner_or_invited?(current_user))
    )

    unless @chapters.include?(@chapter)
      access_denied
      return
    end

    chapter_position = @chapters.index(@chapter)
    if @chapters.length > 1
      @previous_chapter = @chapters[chapter_position - 1] unless chapter_position.zero?
      @next_chapter = @chapters[chapter_position + 1]
    end

    if @work.unrevealed?
      @page_subtitle = t(".unrevealed") + t(".chapter_position", position: @chapter.position.to_s)
    else
      @page_title = work_page_title(@work, @work.title + t(".chapter_position", position: @chapter.position.to_s))
    end

    if params[:view_adult]
      cookies[:view_adult] = "true"
    elsif @work.adult? && !see_adult?
      render "works/_adult", layout: "application" and return
    end

    @kudos = @work.kudos.with_user.includes(:user)

    if current_user.respond_to?(:subscriptions)
      @subscription = current_user.subscriptions.where(subscribable_id: @work.id,
                                                       subscribable_type: "Work").first ||
                      current_user.subscriptions.build(subscribable: @work)
    end

    Reading.update_or_create(@work, current_user) if current_user

    respond_to do |format|
      format.html
      format.js
    end
  end
end
