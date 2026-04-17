module UserPreferences
  extend ActiveSupport::Concern

  def end_first_login
    @user.preference.update_attribute(:first_login, false)

    respond_to do |format|
      format.html { redirect_to(@user) && return }
      format.js
    end
  end

  def end_banner
    @user.preference.update_attribute(:banner_seen, true)

    respond_to do |format|
      format.html { redirect_back_or_to root_path and return }
      format.js
    end
  end

  def end_tos_prompt
    @user.update_attribute(:accepted_tos_version, @current_tos_version)
    head :no_content
  end
end
