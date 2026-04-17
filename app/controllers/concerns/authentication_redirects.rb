module AuthenticationRedirects
  extend ActiveSupport::Concern

  included do
    include PathCleaner
  end

  # Warning: Admin 2FA bypasses this method in SessionsController#authenticate_admin_with_otp_two_factor
  def after_sign_in_path_for(resource)
    if resource.respond_to?(:pwned?) && resource.pwned?
      set_flash_message! :alert, :warn_pwned
      return change_password_user_path(current_user) if resource.is_a?(User)
    end

    return admins_path if resource.is_a?(Admin)

    relative_path(params[:return_to]) || user_path(current_user)
  end

  def not_allowed(fallback = nil)
    flash[:error] = ts("Sorry, you're not allowed to do that.")
    begin
      redirect_to(fallback || root_path)
    rescue StandardError
      redirect_to "/"
    end
  end
end
