module CollectionDeletion
  extend ActiveSupport::Concern

  def confirm_delete
  end

  def destroy
    @hide_dashboard = true
    @collection = Collection.find_by(name: params[:id])
    begin
      @collection.destroy
      flash[:notice] = ts("Collection was successfully deleted.")
    rescue StandardError
      flash[:error] = ts("We couldn't delete that right now, sorry! Please try again later.")
    end
    redirect_to(collections_path)
  end
end
