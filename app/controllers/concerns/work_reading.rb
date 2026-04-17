module WorkReading
  extend ActiveSupport::Concern

  def mark_for_later
    @work = Work.find(params[:id])
    Reading.mark_to_read_later(@work, current_user, true)
    read_later_path = user_readings_path(current_user, show: "to-read")
    flash[:notice] = ts("This work was added to your #{view_context.link_to('Marked for Later list', read_later_path)}.").html_safe if @work.marked_for_later?(current_user)
    redirect_back_or_to root_path
  end

  def mark_as_read
    @work = Work.find(params[:id])
    Reading.mark_to_read_later(@work, current_user, false)
    read_later_path = user_readings_path(current_user, show: "to-read")
    flash[:notice] = ts("This work was removed from your #{view_context.link_to('Marked for Later list', read_later_path)}.").html_safe unless @work.marked_for_later?(current_user)
    redirect_back_or_to root_path
  end
end
