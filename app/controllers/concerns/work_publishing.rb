module WorkPublishing
  extend ActiveSupport::Concern

  def in_moderated_collection
    moderated_collections = []
    @work.collections.each do |collection|
      next unless collection&.moderated? && !collection.user_is_posting_participant?(current_user)
      next unless @work.collection_items.present?

      @work.collection_items.each do |collection_item|
        next unless collection_item.collection == collection

        moderated_collections << collection if collection_item.approved_by_user? && collection_item.unreviewed_by_collection?
      end
    end

    return unless moderated_collections.present?

    flash[:notice] ||= ""
    flash[:notice] += ts(" You have submitted your work to #{moderated_collections.size > 1 ? 'moderated collections (%{all_collections}). It will not become a part of those collections' : "the moderated collection '%{all_collections}'. It will not become a part of the collection"} until it has been approved by a moderator.", all_collections: moderated_collections.map(&:title).join(", "))
  end

  def post_draft
    @user = current_user
    @work = Work.find(params[:id])

    unless @user.is_author_of?(@work)
      flash[:error] = ts("You can only post your own works.")
      redirect_to(current_user) && return
    end

    if @work.posted
      flash[:error] = ts("That work is already posted. Do you want to edit it instead?")
      redirect_to(edit_user_work_path(@user, @work)) && return
    end

    @work.posted = true
    @work.minor_version = @work.minor_version + 1

    unless @work.valid? && @work.save
      flash[:error] = ts("There were problems posting your work.")
      redirect_to(edit_user_work_path(@user, @work)) && return
    end

    @work.word_count = @work.first_chapter.word_count
    @work.save

    if @collection.present? && @collection.moderated?
      redirect_to work_path(@work), notice: ts("Work was submitted to a moderated collection. It will show up in the collection once approved.")
    else
      flash[:notice] = ts("Your work was successfully posted.")
      redirect_to @work
    end
  end
end
