class CollectionsController < ApplicationController
  include CollectionLoading
  include CollectionDisplay
  include CollectionChallenges
  include CollectionForm
  include CollectionDeletion

  before_action :users_only, only: [:new, :edit, :create, :update]
  before_action :load_collection_from_id, only: [:show, :edit, :update, :destroy, :confirm_delete]
  before_action :collection_owners_only, only: [:edit, :update, :destroy, :confirm_delete]
  before_action :check_user_status, only: [:new, :create, :edit, :update, :destroy]
  before_action :validate_challenge_type
  before_action :check_parent_visible, only: [:index]
  cache_sweeper :collection_sweeper
end
