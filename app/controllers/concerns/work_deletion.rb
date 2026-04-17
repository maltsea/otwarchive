module WorkDeletion
  extend ActiveSupport::Concern

  def confirm_delete
  end

  def destroy
    was_draft = !@work.posted?
    title = @work.title

    begin
      @work.destroy
      flash[:notice] = ts("Your work %{title} was deleted.", title: title).html_safe
    rescue StandardError
      flash[:error] = ts("We couldn't delete that right now, sorry! Please try again later.")
    end

    if was_draft
      redirect_to drafts_user_works_path(current_user)
    else
      redirect_to user_works_path(current_user)
    end
  end
end
