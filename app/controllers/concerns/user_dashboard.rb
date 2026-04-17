module UserDashboard
  extend ActiveSupport::Concern

  def load_user
    @user = User.find_by!(login: params[:id])
    @check_ownership_of = @user
  end

  def show
    @page_subtitle = @user.login

    visible = visible_items(current_user)

    @works = visible[:works].order("revised_at DESC").limit(ArchiveConfig.NUMBER_OF_ITEMS_VISIBLE_IN_DASHBOARD)
    @series = visible[:series].order("updated_at DESC").limit(ArchiveConfig.NUMBER_OF_ITEMS_VISIBLE_IN_DASHBOARD)
    @bookmarks = visible[:bookmarks].order("updated_at DESC").limit(ArchiveConfig.NUMBER_OF_ITEMS_VISIBLE_IN_DASHBOARD)
    if current_user.respond_to?(:subscriptions)
      @subscription = current_user.subscriptions.where(subscribable_id: @user.id,
                                                       subscribable_type: "User").first ||
                      current_user.subscriptions.build(subscribable: @user)
    end
  end

  private

  def visible_items(current_user)
    visible_method = current_user.nil? && current_admin.nil? ? :visible_to_all : :visible_to_registered_user

    visible_works = @user.works.send(visible_method)
    visible_series = @user.series.send(visible_method)
    visible_bookmarks = @user.bookmarks.send(visible_method)

    visible_works = visible_works.revealed.non_anon
    visible_series = visible_series.exclude_anonymous
    @fandoms = if @user == User.orphan_account
                 []
               else
                 Fandom.select("tags.*, count(DISTINCT works.id) as work_count")
                   .joins(:filtered_works).group("tags.id").merge(visible_works)
                   .where(filter_taggings: { inherited: false })
                   .order("work_count DESC").load
               end

    {
      works: visible_works,
      series: visible_series,
      bookmarks: visible_bookmarks
    }
  end
end
