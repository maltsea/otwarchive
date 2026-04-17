module CommentForm
  extend ActiveSupport::Concern

  def check_pseud_ownership
    return unless params[:comment][:pseud_id]

    pseud = Pseud.find(params[:comment][:pseud_id])
    return if pseud && current_user && current_user.pseuds.include?(pseud)

    flash[:error] = ts("You can't comment with that pseud.")
    redirect_to root_path
  end

  # GET /comments/new
  def new
    if @commentable.nil?
      flash[:error] = ts("What did you want to comment on?")
      redirect_back_or_to root_path
    else
      @comment = Comment.new
      @controller_name = params[:controller_name] if params[:controller_name]
      @name =
        case @commentable.class.name
        when /Work/
          @commentable.title
        when /Chapter/
          @commentable.work.title
        when /Tag/
          @commentable.name
        when /AdminPost/
          @commentable.title
        when /Comment/
          ts("Previous Comment")
        else
          @commentable.class.name
        end
    end
  end

  # GET /comments/1/edit
  def edit
    respond_to do |format|
      format.html
      format.js
    end
  end

  # POST /comments
  # POST /comments.xml
  def create
    if @commentable.nil?
      flash[:error] = ts("What did you want to comment on?")
      redirect_back_or_to root_path
    else
      @comment = Comment.new(comment_params)
      @comment.ip_address = request.remote_ip
      @comment.user_agent = request.env["HTTP_USER_AGENT"]&.to(499)
      @comment.cloudflare_bot_score = request.env["HTTP_CF_BOT_SCORE"]
      @comment.cloudflare_ja3_hash = request.env["HTTP_CF_JA3_HASH"]
      @comment.cloudflare_ja4 = request.env["HTTP_CF_JA4"]
      @comment.commentable = Comment.commentable_object(@commentable)
      @controller_name = params[:controller_name]

      # First, try saving the comment
      if @comment.save
        flash[:comment_notice] = if @comment.unreviewed?
                                   # i18n-tasks-use t("comments.create.success.moderated.admin_post")
                                   # i18n-tasks-use t("comments.create.success.moderated.work")
                                   t("comments.create.success.moderated.#{@comment.ultimate_parent.model_name.i18n_key}")
                                 else
                                   t("comments.create.success.not_moderated")
                                 end
        respond_to do |format|
          format.html do
            if request.referer&.match(/inbox/)
              redirect_to user_inbox_path(current_user, filters: filter_params, page: params[:page])
            elsif request.referer&.match(/new/) || (@comment.unreviewed? && current_user)
              # If the referer is the new comment page, go to the comment's page
              # instead of reloading the full work.
              # If the comment is unreviewed and commenter is logged in, take
              # them to the comment's page so they can access the edit and
              # delete options for the comment, since unreviewed comments don't
              # appear on the commentable.
              redirect_to comment_path(@comment)
            elsif request.referer == root_url
              # replying on the homepage
              redirect_to root_path
            elsif @comment.unreviewed?
              redirect_to_all_comments(@commentable)
            else
              redirect_to_comment(@comment, { view_full_work: (params[:view_full_work] == "true"), page: params[:page] })
            end
          end
        end
      else
        flash[:error] = ts("Couldn't save comment!")
        render action: "new"
      end
    end
  end

  # PUT /comments/1
  # PUT /comments/1.xml
  def update
    updated_comment_params = comment_params.merge(edited_at: Time.current)
    if @comment.update(updated_comment_params)
      flash[:comment_notice] = ts("Comment was successfully updated.")
      respond_to do |format|
        format.html do
          redirect_to comment_path(@comment) and return if @comment.unreviewed?

          redirect_to_comment(@comment)
        end
        format.js # updating the comment in place
      end
    else
      render action: "edit"
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy
    authorize @comment if logged_in_as_admin?

    parent = @comment.ultimate_parent
    parent_comment = @comment.reply_comment? ? @comment.commentable : nil
    unreviewed = @comment.unreviewed?

    if !@comment.destroy_or_mark_deleted
      # something went wrong?
      flash[:comment_error] = ts("We couldn't delete that comment.")
      redirect_to_comment(@comment)
    elsif unreviewed
      # go back to the rest of the unreviewed comments
      flash[:notice] = ts("Comment deleted.")
      redirect_back_or_to unreviewed_work_comments_path(@comment.commentable)
    elsif parent_comment
      flash[:comment_notice] = ts("Comment deleted.")
      redirect_to_comment(parent_comment)
    else
      flash[:comment_notice] = ts("Comment deleted.")
      redirect_to_all_comments(parent, { show_comments: true })
    end
  end

  # If JavaScript is enabled, use add_comment_reply.js to load the reply form
  # Otherwise, redirect to a comment view with the form already loaded
  def add_comment_reply
    @comment = Comment.new
    respond_to do |format|
      format.html do
        options = { show_comments: true }
        options[:controller] = @commentable.class.to_s.underscore.pluralize
        options[:anchor] = "comment_#{params[:id]}"
        options[:page] = params[:page]
        options[:view_full_work] = params[:view_full_work]
        if @thread_view
          options[:id] = @thread_root
          options[:add_comment_reply_id] = params[:id]
          redirect_to_comment(@commentable, options)
        else
          options[:id] = @commentable.id # work, chapter or other stuff that is not a comment
          options[:add_comment_reply_id] = params[:id]
          redirect_to_all_comments(@commentable, options)
        end
      end
      format.js { @commentable = Comment.find(params[:id]) }
    end
  end

  def cancel_comment_reply
    respond_to do |format|
      format.html do
        options = {}
        options[:show_comments] = params[:show_comments] if params[:show_comments]
        redirect_to_all_comments(@commentable, options)
      end
      format.js { @commentable = Comment.find(params[:id]) }
    end
  end

  def cancel_comment_edit
    respond_to do |format|
      format.html { redirect_to_comment(@comment) }
      format.js
    end
  end

  def delete_comment
    respond_to do |format|
      format.html do
        options = {}
        options[:show_comments] = params[:show_comments] if params[:show_comments]
        options[:delete_comment_id] = params[:id] if params[:id]
        redirect_to_comment(@comment, options)
      end
      format.js
    end
  end

  def cancel_comment_delete
    respond_to do |format|
      format.html do
        options = {}
        options[:show_comments] = params[:show_comments] if params[:show_comments]
        redirect_to_comment(@comment, options)
      end
      format.js
    end
  end
end
