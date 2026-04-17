module CommentDisplay
  extend ActiveSupport::Concern

  def index
    return raise_not_found if @commentable.blank?

    return unless @commentable.instance_of?(Comment)

    # we link to the parent object at the top
    @commentable = @commentable.ultimate_parent
  end

  def unreviewed
    @comments = @commentable.find_all_comments
      .unreviewed_only
      .for_display
      .page(params[:page])
  end

  # GET /comments/1
  # GET /comments/1.xml
  def show
    @comments = CommentDecorator.wrap_comments([@comment])
    @thread_view = true
    @thread_root = @comment
    params[:comment_id] = params[:id]
  end

  def show_comments
    respond_to do |format|
      format.html do
        # if non-ajax it could mean sudden javascript failure OR being redirected from login
        # so we're being extra-nice and preserving any intention to comment along with the show comments option
        options = { show_comments: true }
        options[:add_comment_reply_id] = params[:add_comment_reply_id] if params[:add_comment_reply_id]
        options[:view_full_work] = params[:view_full_work] if params[:view_full_work]
        options[:page] = params[:page]
        redirect_to_all_comments(@commentable, options)
      end

      format.js do
        @comments = CommentDecorator.for_commentable(@commentable, page: params[:page])
      end
    end
  end

  def hide_comments
    respond_to do |format|
      format.html do
        redirect_to_all_comments(@commentable)
      end
      format.js
    end
  end
end
