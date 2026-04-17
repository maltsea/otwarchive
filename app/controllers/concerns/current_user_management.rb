module CurrentUserManagement
  extend ActiveSupport::Concern

  included do
    around_action :set_current_user
  end

  def set_current_user
    User.current_user = logged_in_as_admin? ? current_admin : current_user
    @current_user = current_user

    if current_user
      user_menu_data = Rails.cache.fetch([:user_menu_data, current_user.id], expires_in: 2.hours, race_condition_ttl: 5) do
        {
          current_user_subscriptions_count: current_user.subscriptions.count,
          current_user_visible_work_count: current_user.visible_work_count,
          current_user_bookmarks_count: current_user.bookmarks.count,
          current_user_owned_collections_count: current_user.owned_collections.count,
          current_user_challenge_signups_count: current_user.challenge_signups.count,
          current_user_offer_assignments: current_user.offer_assignments.undefaulted.count + current_user.pinch_hit_assignments.undefaulted.count,
          current_user_unposted_works_size: current_user.unposted_works.size,
          current_user_opendoors: permit?("opendoors"),
          current_user_tag_wrangler: current_user.is_tag_wrangler?
        }
      end

      user_menu_data.each do |variable, value|
        instance_variable_set("@#{variable}", value)
      end
    end

    yield
  ensure
    User.current_user = nil
    @current_user = nil
  end
end
