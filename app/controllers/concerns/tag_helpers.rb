module TagHelpers
  extend ActiveSupport::Concern

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
