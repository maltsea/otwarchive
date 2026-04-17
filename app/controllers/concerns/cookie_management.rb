module CookieManagement
  extend ActiveSupport::Concern

  included do
    after_action :ensure_admin_credentials
    before_action :logout_if_not_user_credentials
    after_action :ensure_user_credentials
  end

  def ensure_admin_credentials
    ensure_cookie(:admin_credentials, logged_in_as_admin?)
  end

  def logout_if_not_user_credentials
    return unless logged_in? && cookies[:user_credentials].nil? && controller_name != "sessions"

    logger.error "Forcing logout"
    sign_out
    redirect_to "/lost_cookie" and return
  end

  def ensure_user_credentials
    ensure_cookie(:user_credentials, logged_in?)
  end

  def ensure_cookie(cookie_name, should_be_present)
    if should_be_present
      cookies[cookie_name] ||= { value: 1, expires: 1.year.from_now }
    else
      cookies.delete(cookie_name)
    end
  end
end
