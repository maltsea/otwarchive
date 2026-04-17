module ChapterOrdering
  extend ActiveSupport::Concern

  def update_positions
    if params[:chapters]
      @work.reorder_list(params[:chapters])
      flash[:notice] = ts("Chapter order has been successfully updated.")
    elsif params[:chapter]
      params[:chapter].each_with_index do |id, position|
        @work.chapters.update(id, position: position + 1)
        (@chapters ||= []) << Chapter.find(id)
      end
    end
    respond_to do |format|
      format.html { redirect_to(@work) && return }
      format.js { head :ok }
    end
  end
end
