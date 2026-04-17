module CommentLoading
  extend ActiveSupport::Concern

  # Get the thing the user is trying to comment on
  def load_commentable
    @thread_view = false
    if params[:comment_id]
      @thread_view = true
      if params[:id]
        @commentable = Comment.find(params[:id])
        @thread_root = Comment.find(params[:comment_id])
      else
        @commentable = Comment.find(params[:comment_id])
        @thread_root = @commentable
      end
    elsif params[:chapter_id]
      @commentable = Chapter.find(params[:chapter_id])
    elsif params[:work_id]
      @commentable = Work.find(params[:work_id])
    elsif params[:admin_post_id]
      @commentable = AdminPost.find(params[:admin_post_id])
    elsif params[:tag_id]
      @commentable = Tag.find_by_name(params[:tag_id])
      @page_subtitle = @commentable.try(:name)
    end
  end

  def load_comment
    @comment = Comment.find(params[:id])
    @check_ownership_of = @comment
    @check_visibility_of = @comment
  end
end
