module ChapterLoading
  extend ActiveSupport::Concern

  def load_work
    @work = params[:work_id] ? Work.find_by(id: params[:work_id]) : Chapter.find_by(id: params[:id]).try(:work)
    if @work.blank?
      flash[:error] = ts("Sorry, we couldn't find the work you were looking for.")
      redirect_to root_path and return
    end
    @check_ownership_of = @work
    @check_visibility_of = @work
  end

  def load_chapter
    @chapter = @work.chapters.find_by(id: params[:id])

    return if @chapter

    flash[:error] = ts("Sorry, we couldn't find the chapter you were looking for.")
    redirect_to work_path(@work)
  end

  def post_chapter
    @work.update_attribute(:posted, true) unless @work.posted
    flash[:notice] = ts("Chapter has been posted!")
  end

  private

  def chapter_params
    params.require(:chapter).permit(:title, :position, :wip_length, :"published_at(3i)",
                                    :"published_at(2i)", :"published_at(1i)", :summary,
                                    :notes, :endnotes, :content, :published_at,
                                    author_attributes: [:byline, { ids: [], coauthors: [] }])
  end
end
