module ChapterForm
  extend ActiveSupport::Concern

  def new
    @chapter = @work.chapters.build(position: @work.number_of_chapters + 1)
  end

  def edit
  end

  def create
    @chapter = @work.chapters.build(chapter_params)
    @work.wip_length = params[:chapter][:wip_length]

    if params[:edit_button] || chapter_cannot_be_saved?
      render :new
    else
      @chapter.posted = true if params[:post_without_preview_button]
      @work.set_revised_at_by_chapter(@chapter)
      if @chapter.save && @work.save
        if @chapter.posted
          post_chapter
          redirect_to [@work, @chapter]
        else
          draft_flash_message(@work)
          redirect_to preview_work_chapter_path(@work, @chapter)
        end
      else
        render :new
      end
    end
  end

  def update
    @chapter.attributes = chapter_params
    @work.wip_length = params[:chapter][:wip_length]

    if params[:edit_button] || chapter_cannot_be_saved?
      render :edit
    elsif params[:preview_button]
      @preview_mode = true
      if @chapter.posted?
        flash[:notice] = ts("This is a preview of what this chapter will look like after your changes have been applied. You should probably read the whole thing to check for problems before posting.")
      else
        draft_flash_message(@work)
      end
      render :preview
    else
      @chapter.posted = true if params[:post_button] || params[:post_without_preview_button]
      @work.posted = true if @chapter.posted? && @chapter == @work.first_chapter
      posted_changed = @chapter.posted_changed?
      @work.set_revised_at_by_chapter(@chapter)
      if @chapter.save && @work.save
        flash[:notice] = ts("Chapter was successfully #{posted_changed ? 'posted' : 'updated'}.")
        redirect_to work_chapter_path(@work, @chapter)
      else
        render :edit
      end
    end
  end

  def draft_flash_message(work)
    flash[:notice] = work.posted ? t("chapters.draft_flash.posted_work") : t("chapters.draft_flash.unposted_work_html", deletion_date: view_context.date_in_zone(work.created_at + 29.days)).html_safe
  end

  def preview
    @preview_mode = true
  end

  def post
    @chapter.posted = true
    @work.set_revised_at_by_chapter(@chapter)
    if @chapter.save && @work.save
      post_chapter
      redirect_to(@work)
    else
      render :preview
    end
  end

  private

  def chapter_cannot_be_saved?
    if @work.invalid?
      @work.errors.full_messages.each do |message|
        @chapter.errors.add(:base, message)
      end
    end

    @chapter.errors.any? || @chapter.invalid?
  end
end
