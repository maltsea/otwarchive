module WorkOwnership
  extend ActiveSupport::Concern

  def remove_user_creatorship
    pseuds_with_author_removed = @work.pseuds - current_user.pseuds

    if pseuds_with_author_removed.empty?
      redirect_to controller: "orphans", action: "new", work_id: @work.id
    else
      @work.remove_author(current_user)
      flash[:notice] = ts("You have been removed as a creator from the work.")
      redirect_to current_user
    end
  end
end
