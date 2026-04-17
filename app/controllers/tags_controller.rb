class TagsController < ApplicationController
  include TagWrangling
  include TagLoading
  include TagDisplay
  include TagSearch
  include TagForm
  include TagWrangle
  include TagHelpers

  before_action :load_collection
  before_action :check_user_status, except: [:show, :index, :show_hidden, :search, :feed]
  before_action :check_permission_to_wrangle, except: [:show, :index, :show_hidden, :search, :feed]
  before_action :load_tag, only: [:show, :edit, :update, :wrangle, :mass_update]
  around_action :record_wrangling_activity, only: [:create, :update, :mass_update]

  caches_page :feed
end
      end

      if noncanonical_fandom_names.present?
        error_messages << ts('The following names are not canonical fandoms: %{noncanonical_fandom_names}.', noncanonical_fandom_names: noncanonical_fandom_names.join(', '))
      end
    end

    flash[:notice] = notice_messages.join('<br />').html_safe unless notice_messages.empty?
    flash[:error] = error_messages.join('<br />').html_safe unless error_messages.empty?

    redirect_to url_for({ controller: :tags, action: :wrangle, id: params[:id] }.merge(options))
  end

  private

  def tag_params
    params.require(:tag).permit(
      :name, :type, :canonical, :unwrangleable, :adult, :sortable_name,
      :meta_tag_string, :sub_tag_string, :merger_string, :syn_string,
      :media_string, :fandom_string, :character_string, :relationship_string,
      :freeform_string,
      associations_to_remove: []
    )
  end

  def tag_search_params
    params.require(:tag_search).permit(
      :query,
      :name,
      :fandoms,
      :type,
      :canonical,
      :wrangling_status,
      :created_at,
      :uses,
      :sort_column,
      :sort_direction
    )
  end
end
