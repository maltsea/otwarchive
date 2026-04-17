module CommentPermissions
  extend ActiveSupport::Concern

  def check_parent_visible
    check_visibility_for(find_parent)
  end

  def check_modify_parent
    parent = find_parent
    # No one can create or update comments on something hidden by an admin.
    if parent.respond_to?(:hidden_by_admin) && parent.hidden_by_admin
      flash[:error] = ts("Sorry, you can't add or edit comments on a hidden work.")
      redirect_to work_path(parent)
    end
    # No one can create or update comments on unrevealed works.
    if parent.respond_to?(:in_unrevealed_collection) && parent.in_unrevealed_collection
      flash[:error] = ts("Sorry, you can't add or edit comments on an unrevealed work.")
      redirect_to work_path(parent)
    end

    # No one can create or update comments on unpublished (A.K.A. unposted) works.
    return unless parent.respond_to?(:posted) && !parent.posted

    flash[:error] = t("comments.check_modify_parent.draft")
    redirect_to work_path(parent)
  end

  def find_parent
    if @comment.present?
      @comment.ultimate_parent
    elsif @commentable.is_a?(Comment)
      @commentable.ultimate_parent
    elsif @commentable.present? && @commentable.respond_to?(:work)
      @commentable.work
    else
      @commentable
    end
  end

  # Check to see if the ultimate_parent is a Work, and if so, if it's restricted
  def check_if_restricted
    parent = find_parent

    return unless parent.respond_to?(:restricted) && parent.restricted? && !(logged_in? || logged_in_as_admin?)

    redirect_to new_user_session_path(restricted_commenting: true, return_to: request.fullpath)
  end

  # Check to see if the ultimate_parent is a Work or AdminPost, and if so, if it allows
  # comments for the current user.
  def check_parent_comment_permissions
    parent = find_parent
    if parent.is_a?(Work)
      translation_key = "work"
    elsif parent.is_a?(AdminPost)
      translation_key = "admin_post"
    else
      return
    end

    if parent.disable_all_comments?
      flash[:error] = t("comments.commentable.permissions.#{translation_key}.disable_all")
      redirect_to parent
    elsif parent.disable_anon_comments? && !logged_in?
      flash[:error] = t("comments.commentable.permissions.#{translation_key}.disable_anon")
      redirect_to parent
    end
  end

  def check_guest_comment_admin_setting
    admin_settings = AdminSetting.current

    return unless admin_settings.guest_comments_off? && guest?

    flash[:error] = t("comments.commentable.guest_comments_disabled")
    redirect_back_or_to find_parent
  end

  def check_guest_replies_preference
    return unless guest? && @commentable.respond_to?(:guest_replies_disallowed?) && @commentable.guest_replies_disallowed?

    flash[:error] = t("comments.check_guest_replies_preference.error")
    redirect_back_or_to find_parent
  end

  def check_unreviewed
    return unless @commentable.respond_to?(:unreviewed?) && @commentable.unreviewed?

    flash[:error] = ts("Sorry, you cannot reply to an unapproved comment.")
    redirect_to logged_in? ? root_path : new_user_session_path(return_to: request.fullpath)
  end

  def check_frozen
    return unless @commentable.respond_to?(:iced?) && @commentable.iced?

    flash[:error] = t("comments.check_frozen.error")
    redirect_back_or_to find_parent
  end

  def check_hidden_by_admin
    return unless @commentable.respond_to?(:hidden_by_admin?) && @commentable.hidden_by_admin?

    flash[:error] = t("comments.check_hidden_by_admin.error")
    redirect_back_or_to find_parent
  end

  def check_not_replying_to_spam
    return unless @commentable.respond_to?(:approved?) && !@commentable.approved?

    flash[:error] = t("comments.check_not_replying_to_spam.error")
    redirect_back_or_to find_parent
  end

  def check_permission_to_review
    parent = find_parent
    return if logged_in_as_admin? || current_user_owns?(parent)

    flash[:error] = ts("Sorry, you don't have permission to see those unreviewed comments.")
    redirect_to logged_in? ? root_path : new_user_session_path(return_to: request.fullpath)
  end

  def check_permission_to_access_single_unreviewed
    return unless @comment.unreviewed?

    parent = find_parent
    return if logged_in_as_admin? || current_user_owns?(parent) || current_user_owns?(@comment)

    flash[:error] = ts("Sorry, that comment is currently in moderation.")
    redirect_to logged_in? ? root_path : new_user_session_path(return_to: request.fullpath)
  end

  def check_permission_to_moderate
    return if logged_in_as_admin? || current_user_owns?(find_parent)

    flash[:error] = ts("Sorry, you don't have permission to moderate that comment.")
    redirect_to(logged_in? ? root_path : new_user_session_path(return_to: comment_path(@comment)))
  end

  def check_tag_wrangler_access
    logged_in_as_admin? || permit?("tag_wrangler") || access_denied if @commentable.is_a?(Tag) || @comment&.parent&.is_a?(Tag)
  end

  # Must be able to delete other people's comments on owned works, not just owned comments!
  def check_permission_to_delete
    access_denied(redirect: @comment) unless logged_in_as_admin? || current_user_owns?(@comment) || current_user_owns?(@comment.ultimate_parent)
  end

  # Comments cannot be edited after they've been replied to or if they are frozen.
  def check_permission_to_edit
    if @comment.iced?
      flash[:error] = t("comments.check_permission_to_edit.error.frozen")
      redirect_back_or_to @comment
    elsif !@comment.count_all_comments.zero?
      flash[:error] = ts("Comments with replies cannot be edited")
      redirect_back_or_to @comment
    end
  end

  # Comments on works can be frozen or unfrozen by admins with proper
  # authorization or the work creator.
  # Comments on tags can be frozen or unfrozen by admins with proper
  # authorization.
  # Comments on admin posts can be frozen or unfrozen by any admin.
  def check_permission_to_modify_frozen_status
    return if permission_to_modify_frozen_status

    # i18n-tasks-use t('comments.freeze.permission_denied')
    # i18n-tasks-use t('comments.unfreeze.permission_denied')
    flash[:error] = t("comments.#{action_name}.permission_denied")
    redirect_back_or_to @comment
  end

  def check_permission_to_modify_hidden_status
    return if policy(@comment).can_hide_comment?

    # i18n-tasks-use t('comments.hide.permission_denied')
    # i18n-tasks-use t('comments.unhide.permission_denied')
    flash[:error] = t("comments.#{action_name}.permission_denied")
    redirect_back_or_to @comment
  end

  def check_guest_email_is_from_suspended_or_banned_user
    return unless guest?

    canonical_email = EmailCanonicalizer.canonicalize(params[:comment][:email])

    user = User.find_by(canonical_email: canonical_email)

    return unless user&.suspended? || user&.banned?

    flash[:error] = t("comments.check_guest_email_is_from_suspended_or_banned_user.error")
    redirect_back_or_to @comment
  end
end
