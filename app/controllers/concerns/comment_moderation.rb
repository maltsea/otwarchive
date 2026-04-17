module CommentModeration
  extend ActiveSupport::Concern

  def review
    if logged_in_as_admin?
      authorize @comment
    else
      return unless current_user_owns?(@comment.ultimate_parent)
    end

    return unless @comment&.unreviewed?

    @comment.toggle!(:unreviewed)
    # mark associated inbox comments as read
    InboxComment.where(user_id: current_user.id, feedback_comment_id: @comment.id).update_all(read: true) unless logged_in_as_admin?
    flash[:notice] = ts("Comment approved.")
    respond_to do |format|
      format.html do
        if params[:approved_from] == "inbox"
          redirect_to user_inbox_path(current_user, page: params[:page], filters: filter_params)
        elsif params[:approved_from] == "home"
          redirect_to root_path
        elsif @comment.ultimate_parent.is_a?(AdminPost)
          redirect_to unreviewed_admin_post_comments_path(@comment.ultimate_parent)
        else
          redirect_to unreviewed_work_comments_path(@comment.ultimate_parent)
        end
        return
      end
      format.js
    end
  end

  def review_all
    authorize @commentable, policy_class: CommentPolicy if logged_in_as_admin?
    unless (@commentable && current_user_owns?(@commentable)) || (@commentable && logged_in_as_admin? && @commentable.is_a?(AdminPost))
      flash[:error] = ts("What did you want to review comments on?")
      redirect_back_or_to root_path
      return
    end

    @comments = @commentable.find_all_comments.unreviewed_only
    @comments.each { |c| c.toggle!(:unreviewed) }
    flash[:notice] = ts("All moderated comments approved.")
    redirect_to @commentable
  end

  def approve
    authorize @comment
    @comment.mark_as_ham!
    redirect_to_all_comments(@comment.ultimate_parent, show_comments: true)
  end

  def reject
    authorize @comment if logged_in_as_admin?
    @comment.mark_as_spam!
    redirect_to_all_comments(@comment.ultimate_parent, show_comments: true)
  end

  # PUT /comments/1/freeze
  def freeze
    # TODO: When AO3-5939 is fixed, we can use
    # comments = @comment.full_set
    if @comment.iced?
      flash[:comment_error] = t(".error")
    else
      comments = @comment.set_to_freeze_or_unfreeze
      Comment.mark_all_frozen!(comments)
      flash[:comment_notice] = t(".success")
    end

    redirect_to_all_comments(@comment.ultimate_parent, show_comments: true)
  rescue StandardError
    flash[:comment_error] = t(".error")
    redirect_to_all_comments(@comment.ultimate_parent, show_comments: true)
  end

  # PUT /comments/1/unfreeze
  def unfreeze
    # TODO: When AO3-5939 is fixed, we can use
    # comments = @comment.full_set
    if @comment.iced?
      comments = @comment.set_to_freeze_or_unfreeze
      Comment.mark_all_unfrozen!(comments)
      flash[:comment_notice] = t(".success")
    else
      flash[:comment_error] = t(".error")
    end

    redirect_to_all_comments(@comment.ultimate_parent, show_comments: true)
  rescue StandardError
    flash[:comment_error] = t(".error")
    redirect_to_all_comments(@comment.ultimate_parent, show_comments: true)
  end

  # PUT /comments/1/hide
  def hide
    if @comment.hidden_by_admin?
      flash[:comment_error] = t(".error")
    else
      @comment.mark_hidden!
      AdminActivity.log_action(current_admin, @comment, action: "hide comment")
      flash[:comment_notice] = t(".success")
    end
    redirect_to_all_comments(@comment.ultimate_parent, show_comments: true)
  end

  # PUT /comments/1/unhide
  def unhide
    if @comment.hidden_by_admin?
      @comment.mark_unhidden!
      AdminActivity.log_action(current_admin, @comment, action: "unhide comment")
      flash[:comment_notice] = t(".success")
    else
      flash[:comment_error] = t(".error")
    end
    redirect_to_all_comments(@comment.ultimate_parent, show_comments: true)
  end
end
