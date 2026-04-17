class UsersController < ApplicationController
  include UserDashboard
  include UserSettings
  include UserActivation
  include UserDeletion
  include UserPreferences

  before_action :check_user_status, only: [:change_username, :changed_username]
  before_action :load_user, except: [:activate, :delete_confirmation, :index]
  before_action :check_ownership, except: [:activate, :change_username, :changed_username, :delete_confirmation, :index, :show]
  before_action :check_ownership_or_admin, only: [:change_username, :changed_username]
end
