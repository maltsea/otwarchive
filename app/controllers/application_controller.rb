class ApplicationController < ActionController::Base
  include ActiveStorage::SetCurrent
  include Pundit::Authorization
  protect_from_forgery with: :exception, prepend: true

  helper :all # include all helpers, all the time

  include HtmlCleaner
  include CookieManagement
  include PagyHelpers
  include ParameterSanitization
  include CurrentUserManagement
  include Authorization
  include ErrorHandling
  include FlashCookieManagement
  include AuthenticationRedirects
  include SortingHelpers
  include LayoutHelpers
  include CollectionLoading

  helper_method :current_user
  helper_method :current_admin
  helper_method :logged_in?
  helper_method :logged_in_as_admin?
  helper_method :guest?

  # Allow totp_attempt parameter in the :sign_in controller for admin two-factor authentication
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:totp_attempt])
  end

  def logged_in?
    user_signed_in?
  end

  def logged_in_as_admin?
    admin_signed_in?
  end

  def guest?
    !(logged_in? || logged_in_as_admin?)
  end

  # Don't get unnecessary data for json requests

  skip_before_action  :load_admin_banner,
                      if: proc { %w[js json].include?(request.format) }
end
