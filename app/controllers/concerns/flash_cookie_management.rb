module FlashCookieManagement
  extend ActiveSupport::Concern

  included do
    before_action :clear_flash_cookie
    after_action :check_for_flash
  end

  def clear_flash_cookie
    cookies.delete(:flash_is_set)
  end

  def check_for_flash
    cookies[:flash_is_set] = 1 unless flash.empty?
  end

  def redirect_to(*args, **kwargs)
    super.tap do
      check_for_flash
    end
  end
end
