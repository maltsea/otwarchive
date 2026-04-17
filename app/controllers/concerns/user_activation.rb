module UserActivation
  extend ActiveSupport::Concern

  def activate
    if params[:id].blank?
      flash[:error] = ts("Your activation key is missing.")
      redirect_to root_path

      return
    end

    @user = User.find_by(confirmation_token: params[:id])

    unless @user
      flash[:error] = ts("Your activation key is invalid. If you didn't activate within #{AdminSetting.current.days_to_purge_unactivated * 7} days, your account was deleted. Please sign up again, or contact support via the link in our footer for more help.").html_safe
      redirect_to root_path

      return
    end

    if @user.active?
      flash[:error] = ts("Your account has already been activated.")
      redirect_to @user

      return
    end

    @user.activate

    flash[:notice] = ts("Account activation complete! Please log in.")

    @user.create_log_item(action: ArchiveConfig.ACTION_ACTIVATE)

    external_authors = []
    external_authors << ExternalAuthor.find_by(email: @user.email)
    @invitation = @user.invitation
    external_authors << @invitation.external_author if @invitation
    external_authors.compact!

    unless external_authors.empty?
      external_authors.each do |external_author|
        external_author.claim!(@user)
      end

      flash[:notice] += ts(" We found some works already uploaded to the Archive of Our Own that we think belong to you! You'll see them on your homepage when you've logged in.")
    end

    redirect_to(new_user_session_path)
  end

  def confirm_change_email
    @page_subtitle = t(".browser_title")

    render :change_email and return unless reauthenticate

    if params[:new_email].blank?
      flash.now[:error] = t("users.confirm_change_email.blank_email")
      render :change_email and return
    end

    @new_email = params[:new_email]

    if @new_email.downcase == @user.email.downcase
      flash.now[:error] = t("users.confirm_change_email.same_as_current")
      render :change_email and return
    end

    if @new_email.downcase != params[:email_confirmation].downcase
      flash.now[:error] = t("users.confirm_change_email.nonmatching_email")
      render :change_email and return
    end

    old_email = @user.email
    @user.email = @new_email
    return if @user.valid?(:update)

    @user.email = old_email
    render :change_email
  end

  def changed_email
    new_email = params[:new_email]

    old_email = @user.email
    @user.email = new_email

    if @user.save
      I18n.with_locale(@user.preference.locale_for_mails) do
        UserMailer.change_email(@user.id, old_email, new_email).deliver_later
      end
    else
      @user.email = old_email
    end

    render :change_email
  end

  def reconfirm_email
    confirmed_user = User.confirm_by_token(params[:confirmation_token])

    if confirmed_user.errors.empty?
      flash[:notice] = t(".success")
    else
      flash[:error] = t(".invalid_token")
    end

    redirect_to change_email_user_path(@user)
  end
end
