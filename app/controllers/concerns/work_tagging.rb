module WorkTagging
  extend ActiveSupport::Concern

  def edit_tags
    authorize @work if logged_in_as_admin?
    @page_subtitle = t(".page_title")
  end

  def update_tags
    authorize @work if logged_in_as_admin?

    @work.preview_mode = !!(params[:preview_button] || params[:edit_button])
    @work.attributes = work_tag_params

    if params[:edit_button] || work_cannot_be_saved?
      render :edit_tags
    elsif params[:preview_button]
      @preview_mode = true
      @page_subtitle = t(".page_title")
      render :preview_tags
    elsif params[:save_button]
      @work.save
      flash[:notice] = ts("Tags were successfully updated.")
      redirect_to(@work)
    else
      @work.posted = true
      @work.minor_version = @work.minor_version + 1
      @work.save
      flash[:notice] = ts("Work was successfully updated.")
      redirect_to(@work)
    end
  end

  def preview_tags
    @preview_mode = true
  end
end
