# encoding=utf-8

class WorksController < ApplicationController
  include WorksHelper
  include WorkLoading
  include WorkParams
  include WorkListing
  include WorkDisplay
  include WorkForm
  include WorkTagging
  include WorkOwnership
  include WorkImporting
  include WorkPublishing
  include WorkBatchEditing
  include WorkDeletion
  include WorkReading

  # only registered users and NOT admin should be able to create new works
  before_action :load_collection
  before_action :load_owner, only: [:index]
  before_action :users_only, except: [:index, :show, :navigate, :search, :collected, :edit_tags, :update_tags, :drafts, :share]
  before_action :check_user_status, except: [:index, :edit, :edit_multiple, :confirm_delete_multiple, :delete_multiple, :confirm_delete, :destroy, :show, :show_multiple, :navigate, :search, :collected, :share]
  before_action :check_user_not_suspended, only: [:edit, :confirm_delete, :destroy, :show_multiple, :edit_multiple, :confirm_delete_multiple, :delete_multiple]
  before_action :load_work, except: [:new, :create, :import, :index, :show_multiple, :edit_multiple, :update_multiple, :delete_multiple, :search, :drafts, :collected]
  # this only works to check ownership of a SINGLE item and only if load_work has happened beforehand
  before_action :check_ownership, except: [:index, :show, :navigate, :new, :create, :import, :show_multiple, :edit_multiple, :edit_tags, :update_tags, :update_multiple, :delete_multiple, :search, :mark_for_later, :mark_as_read, :drafts, :collected, :share]
  # admins should have the ability to edit tags (:edit_tags, :update_tags) as per our ToS
  before_action :check_ownership_or_admin, only: [:edit_tags, :update_tags]
  before_action :log_admin_activity, only: [:update_tags]
  before_action :check_parent_visible, only: [:navigate]
  before_action :check_visibility, only: [:show, :navigate, :share, :mark_for_later, :mark_as_read]

  before_action :load_first_chapter, only: [:show, :edit, :update, :preview]

  cache_sweeper :collection_sweeper
  cache_sweeper :feed_sweeper
end
