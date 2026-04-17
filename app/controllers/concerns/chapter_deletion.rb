module ChapterDeletion
  extend ActiveSupport::Concern

  def confirm_delete
  end

  def destroy
    if @chapter.is_only_chapter? || @chapter.only_non_draft_chapter?
      flash[:error] = t(".only_chapter")
      redirect_to(edit_work_path(@work))
      return
    end

    was_draft = !@chapter.posted?
    if @chapter.destroy
      @work.minor_version = @work.minor_version + 1 unless was_draft
      @work.set_revised_at
      @work.save
      flash[:notice] = ts("The chapter #{was_draft ? 'draft ' : ''}was successfully deleted.")
    else
      flash[:error] = ts("Something went wrong. Please try again.")
    end
    redirect_to controller: "works", action: "show", id: @work
  end
end
