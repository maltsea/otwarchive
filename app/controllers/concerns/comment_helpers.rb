module CommentHelpers
  extend ActiveSupport::Concern

  include WorksHelper
  include BlockHelper

  def check_blocked
    parent = find_parent

    if blocked_by?(parent)
      flash[:comment_error] = t("comments.check_blocked.parent")
      redirect_to_all_comments(parent, show_comments: true)
    elsif @comment && blocked_by_comment?(@comment.commentable)
      # edit and update set @comment to the comment being edited
      flash[:comment_error] = t("comments.check_blocked.reply")
      redirect_to_all_comments(parent, show_comments: true)
    elsif @comment.nil? && blocked_by_comment?(@commentable)
      # new, create, and add_comment_reply don't set @comment, but do set @commentable
      flash[:comment_error] = t("comments.check_blocked.reply")
      redirect_to_all_comments(parent, show_comments: true)
    end
  end

  RATE_LIMIT_STORE = ActiveSupport::Cache::RedisCacheStore.new(redis: REDIS_RATELIMITS, pool: false)

  rate_limit to: ArchiveConfig.RATE_LIMIT_USER_COMMENTING_NUMBER,
             within: ArchiveConfig.RATE_LIMIT_USER_COMMENTING_PERIOD.seconds,
             by: -> { current_user.id },
             if: -> { should_rate_limit },
             with: -> { rate_limited },
             store: RATE_LIMIT_STORE

  def should_rate_limit
    return false unless action_name == "create" || action_name == "update"

    return false unless logged_in? # Guest comment rate limits are not handled here

    return false unless current_user.should_spam_check_comments?

    parent = find_parent
    return false if parent.is_a?(Tag)

    return false if current_user.is_author_of?(parent)

    true
  end

  def rate_limited
    respond_to do |format|
      format.html do
        redirect_to controller: "errors", action: "429"
      end
      format.js do
        render json: {
          error_message: t("comments.rate_limited.error")
        }, status: :too_many_requests
      end
    end
  end

  def set_page_subtitle
    parent = find_parent
    return unless parent

    name = if parent.is_a?(Work)
             work_page_title(parent, parent.title, { omit_archive_name: true })
           else
             parent.commentable_name
           end

    # i18n-tasks-use t("comments.index.page_title")
    # i18n-tasks-use t("comments.new.page_title")
    # i18n-tasks-use t("comments.show.page_title")
    # i18n-tasks-use t("comments.unreviewed.page_title")
    @page_subtitle = t(".page_title", name: name, comment_id: @comment&.id)
  end
end
