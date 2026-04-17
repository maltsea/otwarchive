module UserDeletion
  extend ActiveSupport::Concern

  def destroy
    @hide_dashboard = true
    @works = @user.works.where(posted: true)
    @sole_owned_collections = @user.sole_owned_collections

    if @works.empty? && @sole_owned_collections.empty?
      @user.wipeout_unposted_works
      @user.destroy_empty_series

      @user.destroy
      flash[:notice] = ts("You have successfully deleted your account.")

      redirect_to(delete_confirmation_path)
    elsif params[:coauthor].blank? && params[:sole_author].blank?
      @sole_authored_works = @user.sole_authored_works
      @coauthored_works = @user.coauthored_works

      render("delete_preview") && return
    elsif params[:coauthor] || params[:sole_author]
      destroy_author
    end
  end

  def delete_confirmation
    redirect_to user_path(current_user) if logged_in?
  end

  private

  def destroy_author
    @sole_authored_works = @user.sole_authored_works
    @coauthored_works = @user.coauthored_works

    if params[:cancel_button]
      flash[:notice] = ts("Account deletion canceled.")
      redirect_to user_profile_path(@user)

      return
    end

    if params[:coauthor] == "keep_pseud" || params[:coauthor] == "orphan_pseud"
      pseuds = @user.pseuds
      works = @coauthored_works
      use_default = params[:use_default] == "true" || params[:coauthor] == "orphan_pseud"
      Creatorship.orphan(pseuds, works, use_default)
    elsif params[:coauthor] == "remove"
      @coauthored_works.each do |w|
        w.remove_author(@user)
      end
    end

    if params[:sole_author] == "keep_pseud" || params[:sole_author] == "orphan_pseud"
      pseuds = @user.pseuds
      works = @sole_authored_works
      use_default = params[:use_default] == "true" || params[:sole_author] == "orphan_pseud"
      Creatorship.orphan(pseuds, works, use_default)
      Collection.orphan(pseuds, @sole_owned_collections, default: use_default)
    elsif params[:sole_author] == "delete"
      @sole_authored_works.each(&:destroy)
      @sole_owned_collections.each(&:destroy)
    end

    @works = @user.works.where(posted: true)

    if @works.blank?
      @user.wipeout_unposted_works
      @user.destroy_empty_series

      @user.destroy

      flash[:notice] = ts("You have successfully deleted your account.")
      redirect_to(delete_confirmation_path)
    else
      flash[:error] = ts("Sorry, something went wrong! Please try again.")
      redirect_to(@user)
    end
  end
end
