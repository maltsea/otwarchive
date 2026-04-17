module Authorization
  extend ActiveSupport::Concern

  def is_registered_user?
    logged_in? || logged_in_as_admin?
  end

  def is_admin?
    logged_in_as_admin?
  end

  def pundit_user
    current_admin
  end

  def see_adult?
    params[:anchor] = "comments" if params[:show_comments] && params[:anchor].blank?
    return true if cookies[:view_adult] || logged_in_as_admin?
    return false unless current_user
    return true if current_user.is_author_of?(@work)
    return true if current_user.preference && current_user.preference.adult

    false
  end

  def use_caching?
    %w[staging production test].include?(Rails.env) && AdminSetting.current.enable_test_caching?
  end

  def authenticate_admin!
    if admin_signed_in?
      super
    else
      redirect_to root_path, notice: "I'm sorry, only an admin can look at that area"
      ## if you want render 404 page
      ## render file: File.join(Rails.root, 'public/404'), formats: [:html], status: 404, layout: false
    end
  end

  # Filter method - keeps users out of admin areas
  def admin_only
    authenticate_admin! || admin_only_access_denied
  end

  # Filter method to prevent admin users from accessing certain actions
  def users_only
    logged_in? || access_denied
  end

  # Filter method - requires user to have opendoors privs
  def opendoors_only
    (logged_in? && permit?("opendoors")) || access_denied
  end

  # Redirect as appropriate when an access request fails.
  #
  # The default action is to redirect to the login screen.
  #
  # Override this method in your controllers if you want to have special
  # behavior in case the user is not authorized
  # to access the requested action.  For example, a popup window might
  # simply close itself.
  def access_denied(options = {})
    destination = options[:redirect]
    if logged_in?
      destination ||= user_path(current_user)
      # i18n-tasks-use t('users.reconfirm_email.access_denied.logged_in')
      flash[:error] = t(".access_denied.logged_in", default: t("application.access_denied.access_denied.logged_in")) # rubocop:disable I18n/DefaultTranslation
    else
      destination ||= new_user_session_path(return_to: request.fullpath)
      flash[:error] = ts "Sorry, you don't have permission to access the page you were trying to reach. Please log in."
    end
    redirect_to destination
    false
  end

  def admin_only_access_denied
    respond_to do |format|
      format.html do
        flash[:error] = t("admin.access.page_access_denied")
        redirect_to root_path
      end
      format.json do
        errors = [t("admin.access.action_access_denied")]
        render json: { errors: errors }, status: :forbidden
      end
      format.js do
        flash[:error] = t("admin.access.page_access_denied")
        render js: "window.location.href = '#{root_path}';"
      end
    end
  end

  # Filter method - prevents users from logging in as admin
  def user_logout_required
    if logged_in?
      flash[:notice] = "Please log out of your user account first!"
      redirect_to root_path
    end
  end

  # Prevents admin from logging in as users
  def admin_logout_required
    if logged_in_as_admin?
      flash[:notice] = "Please log out of your admin account first!"
      redirect_to root_path
    end
  end

  def collection_maintainers_only
    (logged_in? && @collection && @collection.user_is_maintainer?(current_user)) || access_denied
  end

  def collection_owners_only
    (logged_in? && @collection && @collection.user_is_owner?(current_user)) || access_denied
  end

  def current_user_owns?(item)
    !item.nil? && current_user.is_a?(User) && (item.is_a?(User) ? current_user == item : current_user.is_author_of?(item))
  end

  def check_ownership
    access_denied(redirect: @check_ownership_of) unless current_user_owns?(@check_ownership_of)
  end

  def check_ownership_or_admin
    return true if logged_in_as_admin?

    access_denied(redirect: @check_ownership_of) unless current_user_owns?(@check_ownership_of)
  end

  def check_visibility
    if @check_visibility_of.respond_to?(:restricted) && @check_visibility_of.restricted && User.current_user.nil?
      redirect_to new_user_session_path(restricted: true, return_to: request.fullpath)
    elsif @check_visibility_of.is_a? Skin
      access_denied unless logged_in_as_admin? || current_user_owns?(@check_visibility_of) || @check_visibility_of.official?
    else
      is_hidden = (@check_visibility_of.respond_to?(:visible) && !@check_visibility_of.visible) ||
                  (@check_visibility_of.respond_to?(:visible?) && !@check_visibility_of.visible?) ||
                  (@check_visibility_of.respond_to?(:hidden_by_admin?) && @check_visibility_of.hidden_by_admin?)
      can_view_hidden = logged_in_as_admin? || current_user_owns?(@check_visibility_of)
      access_denied if is_hidden && !can_view_hidden
    end
  end

  def check_permission_to_wrangle
    if AdminSetting.current.tag_wrangling_off? && !logged_in_as_admin?
      flash[:error] = "Wrangling is disabled at the moment. Please check back later."
      redirect_to root_path
    else
      logged_in_as_admin? || permit?("tag_wrangler") || access_denied
    end
  end

  def check_visibility_for(parent)
    return if logged_in_as_admin? || current_user_owns?(parent)

    access_denied(redirect: root_path) if parent.try(:hidden_by_admin) || parent.try(:in_unrevealed_collection) || (parent.respond_to?(:visible?) && !parent.visible?)
  end

  protected

  def check_user_status
    if current_user.is_a?(User) && (current_user.suspended? || current_user.banned?)
      if current_user.suspended?
        suspension_end = current_user.suspended_until

        # Unban threshold is 6:51pm, 12 hours after the unsuspend_users rake task located in schedule.rb is run at 6:51am
        unban_theshold = DateTime.new(suspension_end.year, suspension_end.month, suspension_end.day, 18, 51, 0, "+00:00")

        suspension_end = suspension_end.next_day(1) if suspension_end > unban_theshold
        localized_suspension_end = view_context.date_in_zone(suspension_end)
        flash[:error] = t("users.status.suspension_notice_html", suspended_until: localized_suspension_end, contact_abuse_link: view_context.link_to(t("users.contact_abuse"), new_abuse_report_path))
      else
        flash[:error] = t("users.status.ban_notice_html", contact_abuse_link: view_context.link_to(t("users.contact_abuse"), new_abuse_report_path))
      end
      redirect_to current_user
    end
  end

  def check_user_not_suspended
    return unless current_user.is_a?(User) && current_user.suspended?

    suspension_end = current_user.suspended_until

    # Unban threshold is 6:51pm, 12 hours after the unsuspend_users rake task located in schedule.rb is run at 6:51am
    unban_theshold = DateTime.new(suspension_end.year, suspension_end.month, suspension_end.day, 18, 51, 0, "+00:00")

    suspension_end = suspension_end.next_day(1) if suspension_end > unban_theshold
    localized_suspension_end = view_context.date_in_zone(suspension_end)

    flash[:error] = t("users.status.suspension_notice_html", suspended_until: localized_suspension_end, contact_abuse_link: view_context.link_to(t("users.contact_abuse"), new_abuse_report_path))

    redirect_to current_user
  end
end
