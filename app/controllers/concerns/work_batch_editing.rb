module WorkBatchEditing
  extend ActiveSupport::Concern

  def show_multiple
    @page_subtitle = ts("Edit Multiple Works")
    @user = current_user

    @works = owned_works(ids: params[:work_ids])

    @works_by_fandom = @works.joins(:taggings)
      .joins("inner join tags on taggings.tagger_id = tags.id AND tags.type = 'Fandom'")
      .select("distinct tags.name as fandom, works.id, works.title, works.posted").group_by(&:fandom)
  end

  def edit_multiple
    redirect_to(new_orphan_path(work_ids: params[:work_ids])) && return if params[:commit] == "Orphan"

    @page_subtitle = ts("Edit Multiple Works")
    @user = current_user
    @works = owned_works(ids: params[:work_ids]).select("distinct works.*")

    render("confirm_delete_multiple") && return if params[:commit] == "Delete"
  end

  def confirm_delete_multiple
    @user = current_user
    @works = owned_works(ids: params[:work_ids]).select("distinct works.*")
  end

  def delete_multiple
    @user = current_user
    @works = owned_works(ids: params[:work_ids], readonly: false)
    titles = @works.collect(&:title)

    @works.each(&:destroy)

    flash[:notice] = ts("Your works %{titles} were deleted.", titles: titles.join(", "))
    redirect_to show_multiple_user_works_path(@user)
  end

  def update_multiple
    @user = current_user
    @works = owned_works(ids: params[:work_ids], readonly: false)
    @errors = []

    updated_work_params = work_params.reject { |_key, value| value.blank? }

    @works.each do |work|
      @errors << ts("The work %{title} could not be edited: %{error}", title: work.title, error: work.errors.full_messages.join(" ")).html_safe unless work.update(updated_work_params)

      if params[:remove_me]
        if work.pseuds.where.not(user_id: current_user.id).exists?
          work.remove_author(current_user)
        else
          @errors << ts("You cannot remove yourself as co-creator of the work %{title} because you are the only listed creator. If you have invited another co-creator, you must wait for them to accept before you can remove yourself.", title: work.title)
        end
      end
    end

    if @errors.empty?
      flash[:notice] = ts("Your edits were put through! Please check over the works to make sure everything is right.")
    else
      flash[:error] = @errors
    end

    redirect_to show_multiple_user_works_path(@user, work_ids: @works.map(&:id))
  end

  private

  def owned_works(ids: nil, readonly: true)
    scope = Work.joins(pseuds: :user).where(users: { id: current_user.id })
    scope = scope.where(id: ids) if ids.present?
    scope = scope.readonly(false) unless readonly
    scope
  end
end
