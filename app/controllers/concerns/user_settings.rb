module UserSettings
  extend ActiveSupport::Concern

  def change_email
    @page_subtitle = t(".page_title")
  end

  def change_password
    @page_subtitle = t(".page_title")
  end

  def change_username
    authorize @user if logged_in_as_admin?
    @page_subtitle = t(".page_title")
  end

  def changed_password
    render(:change_password) && return unless params[:password] && reauthenticate

    @user.password = params[:password]
    @user.password_confirmation = params[:password_confirmation]

    if @user.save
      flash[:notice] = ts("Your password has been changed. To protect your account, you have been logged out of all active sessions. Please log in with your new password.")
      @user.create_log_item(action: ArchiveConfig.ACTION_PASSWORD_CHANGE)

      redirect_to(user_profile_path(@user)) && return
    else
      render(:change_password) && return
    end
  end

  def changed_username
    authorize @user if logged_in_as_admin?
    render(:change_username) && return if params[:new_login].blank?

    @new_login = params[:new_login]

    unless logged_in_as_admin? || @user.valid_password?(params[:password])
      flash[:error] = t(".user.incorrect_password_html", contact_support_link: helpers.link_to(t(".user.contact_support"), new_feedback_report_path))
      render(:change_username) && return
    end

    if @new_login == @user.login
      flash.now[:error] = t(".new_username_must_be_different")
      render :change_username and return
    end

    old_login = @user.login
    @user.login = @new_login
    @user.ticket_number = params[:ticket_number]

    if @user.save
      if logged_in_as_admin?
        flash[:notice] = t(".admin.successfully_updated")
        redirect_to admin_user_path(@user)
      else
        I18n.with_locale(@user.preference.locale_for_mails) do
          UserMailer.change_username(@user, old_login).deliver_later
        end

        flash[:notice] = t(".user.successfully_updated")
        redirect_to @user
      end
    else
      @user.reload
      render :change_username
    end
  end

  private

  def reauthenticate
    if params[:password_check].blank?
      return wrong_password!(params[:new_email],
                             t("users.confirm_change_email.blank_password"),
                             t("users.changed_password.blank_password"))
    end

    if @user.valid_password?(params[:password_check])
      true
    else
      wrong_password!(params[:new_email],
                      t("users.confirm_change_email.wrong_password_html", contact_support_link: helpers.link_to(t("users.confirm_change_email.contact_support"), new_feedback_report_path)),
                      t("users.changed_password.wrong_password_html", contact_support_link: helpers.link_to(t("users.changed_password.contact_support"), new_feedback_report_path)))
    end
  end

  def wrong_password!(condition, if_true, if_false)
    flash.now[:error] = condition ? if_true : if_false
    @wrong_password = true

    false
  end
end
