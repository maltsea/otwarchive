module WorkDisplay
  extend ActiveSupport::Concern

  def show
    if @work.unrevealed?
      @page_subtitle = t(".page_title.unrevealed")
    else
      @page_title = work_page_title(@work, @work.title)
    end

    if params[:view_adult]
      cookies[:view_adult] = "true"
    elsif @work.adult? && !see_adult?
      render("_adult", layout: "application") && return
    end

    if @work.chaptered?
      if params[:view_full_work] || (logged_in? && current_user.preference.try(:view_full_works))
        @chapters = @work.chapters_in_order(
          include_drafts: (logged_in_as_admin? ||
                           @work.user_is_owner_or_invited?(current_user))
        )
      else
        flash.keep
        redirect_to([@work, @chapter, { only_path: true }]) && return
      end
    end

    @tag_categories_limited = Tag::VISIBLE - ["ArchiveWarning"]
    @kudos = @work.kudos.with_user.includes(:user)

    if current_user.respond_to?(:subscriptions)
      @subscription = current_user.subscriptions.where(subscribable_id: @work.id,
                                                       subscribable_type: "Work").first ||
                      current_user.subscriptions.build(subscribable: @work)
    end

    render :show
    Reading.update_or_create(@work, current_user) if current_user
  end

  def share
    if request.xhr?
      if @work.unrevealed?
        render template: "errors/404", status: :not_found
      else
        render layout: false
      end
    else
      flash[:error] = ts("Sorry, you need to have JavaScript enabled for this.")
      redirect_back_or_to @work
    end
  end

  def navigate
    @chapters = @work.chapters_in_order(
      include_content: false,
      include_drafts: (logged_in_as_admin? ||
                       @work.user_is_owner_or_invited?(current_user))
    )
  end
end
