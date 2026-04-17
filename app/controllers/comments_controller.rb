class CommentsController < ApplicationController
  include CommentLoading
  include CommentPermissions
  include CommentDisplay
  include CommentForm
  include CommentModeration
  include CommentHelpers

  before_action :load_commentable,
                only: [:index, :new, :create, :edit, :update, :show_comments,
                       :hide_comments, :add_comment_reply,
                       :cancel_comment_reply, :delete_comment,
                       :cancel_comment_delete, :unreviewed, :review_all]
  before_action :check_user_status, only: [:new, :create, :edit, :update, :destroy]
  before_action :load_comment, only: [:show, :edit, :update, :delete_comment, :destroy, :cancel_comment_edit, :cancel_comment_delete, :review, :approve, :reject, :freeze, :unfreeze, :hide, :unhide]
  before_action :check_visibility, only: [:show]
  before_action :check_if_restricted
  before_action :check_tag_wrangler_access
  before_action :check_parent_visible
  before_action :check_modify_parent,
                only: [:new, :create, :edit, :update, :add_comment_reply,
                       :cancel_comment_reply, :cancel_comment_edit]
  before_action :check_pseud_ownership, only: [:create, :update]
  before_action :check_ownership, only: [:edit, :update, :cancel_comment_edit]
  before_action :check_permission_to_edit, only: [:edit, :update]
  before_action :check_permission_to_delete, only: [:delete_comment, :destroy]
  before_action :check_guest_comment_admin_setting, only: [:new, :create, :add_comment_reply]
  before_action :check_parent_comment_permissions, only: [:new, :create, :add_comment_reply]
  before_action :check_unreviewed, only: [:add_comment_reply]
  before_action :check_frozen, only: [:new, :create, :add_comment_reply]
  before_action :check_hidden_by_admin, only: [:new, :create, :add_comment_reply]
  before_action :check_not_replying_to_spam, only: [:new, :create, :add_comment_reply]
  before_action :check_guest_replies_preference, only: [:new, :create, :add_comment_reply]
  before_action :check_permission_to_review, only: [:unreviewed]
  before_action :check_permission_to_access_single_unreviewed, only: [:show]
  before_action :check_permission_to_moderate, only: [:approve, :reject]
  before_action :check_permission_to_modify_frozen_status, only: [:freeze, :unfreeze]
  before_action :check_permission_to_modify_hidden_status, only: [:hide, :unhide]
  before_action :check_guest_email_is_from_suspended_or_banned_user, only: [:create]
  before_action :admin_logout_required, only: [:new, :create, :add_comment_reply]
  before_action :set_page_subtitle, only: [:index, :new, :show, :unreviewed]

  before_action :check_blocked, only: [:new, :create, :add_comment_reply, :edit, :update]

  protected

  # redirect to a particular comment in a thread, going into the thread
  # if necessary to display it
  def redirect_to_comment(comment, options = {})
    if comment.depth > ArchiveConfig.COMMENT_THREAD_MAX_DEPTH
      default_options = if comment.ultimate_parent.is_a?(Tag)
                          {
                            controller: :comments,
                            action: :show,
                            id: comment.commentable.id,
                            tag_id: comment.ultimate_parent.to_param,
                            anchor: "comment_#{comment.id}"
                          }
                        else
                          {
                            controller: comment.commentable.class.to_s.underscore.pluralize,
                            action: :show,
                            id: (comment.commentable.is_a?(Tag) ? comment.commentable.to_param : comment.commentable.id),
                            anchor: "comment_#{comment.id}"
                          }
                        end
      # display the comment's direct parent (and its associated thread)
      redirect_to(url_for(default_options.merge(options)))
    else
      # need to redirect to the specific chapter; redirect_to_all will then retrieve full work view if applicable
      redirect_to_all_comments(comment.parent, options.merge({ show_comments: true, anchor: "comment_#{comment.id}" }))
    end
  end

  def redirect_to_all_comments(commentable, options = {})
    default_options = { anchor: "comments" }
    options = default_options.merge(options)

    if commentable.is_a?(Tag)
      redirect_to comments_path(tag_id: commentable.to_param,
                                add_comment_reply_id: options[:add_comment_reply_id],
                                delete_comment_id: options[:delete_comment_id],
                                page: options[:page],
                                anchor: options[:anchor])
    else
      commentable = commentable.work if commentable.is_a?(Chapter) && (options[:view_full_work] || current_user.try(:preference).try(:view_full_works))
      redirect_to polymorphic_path(commentable,
                                   options.slice(:show_comments,
                                                 :add_comment_reply_id,
                                                 :delete_comment_id,
                                                 :view_full_work,
                                                 :anchor,
                                                 :page))
    end
  end

  def permission_to_modify_frozen_status
    parent = find_parent
    return true if policy(@comment).can_freeze_comment?
    return true if parent.is_a?(Work) && current_user_owns?(parent)

    false
  end

  private

  def comment_params
    params.require(:comment).permit(
      :pseud_id, :comment_content, :name, :email, :edited_at
    )
  end

  def filter_params
    params.slice(:filters).permit(filters: [:date, :read, :replied_to])[:filters]
  end
end
