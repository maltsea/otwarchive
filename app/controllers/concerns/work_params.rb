module WorkParams
  extend ActiveSupport::Concern

  private

  def clean_work_search_params
    QueryCleaner.new(work_search_params || {}).clean
  end

  def build_options(params)
    pseuds_to_apply = Pseud.find_by(name: params[:pseuds_to_apply]) if params[:pseuds_to_apply]

    {
      pseuds: pseuds_to_apply,
      post_without_preview: params[:post_without_preview],
      importing_for_others: params[:importing_for_others],
      restricted: params[:restricted],
      moderated_commenting_enabled: params[:moderated_commenting_enabled],
      comment_permissions: params[:comment_permissions],
      override_tags: params[:override_tags],
      detect_tags: params[:detect_tags] == "true",
      fandom: params[:work][:fandom_string],
      archive_warning: params[:work][:archive_warning_strings],
      character: params[:work][:character_string],
      rating: params[:work][:rating_string],
      relationship: params[:work][:relationship_string],
      category: params[:work][:category_strings],
      freeform: params[:work][:freeform_string],
      notes: params[:notes],
      encoding: params[:encoding],
      external_author_name: params[:external_author_name],
      external_author_email: params[:external_author_email],
      external_coauthor_name: params[:external_coauthor_name],
      external_coauthor_email: params[:external_coauthor_email],
      language_id: params[:language_id]
    }.compact_blank!
  end

  def work_params
    params.require(:work).permit(
      :rating_string, :fandom_string, :relationship_string, :character_string,
      :archive_warning_string, :category_string,
      :freeform_string, :summary, :notes, :endnotes, :collection_names, :recipients, :wip_length,
      :backdate, :language_id, :work_skin_id, :restricted, :comment_permissions,
      :moderated_commenting_enabled, :title, :pseuds_to_add, :collections_to_add,
      current_user_pseud_ids: [],
      collections_to_remove: [],
      challenge_assignment_ids: [],
      challenge_claim_ids: [],
      category_strings: [],
      archive_warning_strings: [],
      author_attributes: [:byline, { ids: [], coauthors: [] }],
      series_attributes: [:id, :title],
      parent_work_relationships_attributes: [
        :url, :title, :author, :language_id, :translation
      ],
      chapter_attributes: [
        :title, :"published_at(3i)", :"published_at(2i)", :"published_at(1i)",
        :published_at, :content
      ]
    )
  end

  def work_tag_params
    params.require(:work).permit(
      :rating_string, :fandom_string, :relationship_string, :character_string,
      :archive_warning_string, :category_string, :freeform_string, :language_id,
      category_strings: [],
      archive_warning_strings: []
    )
  end

  def work_search_params
    params.require(:work_search).permit(
      :query,
      :title,
      :creators,
      :revised_at,
      :complete,
      :single_chapter,
      :word_count,
      :language_id,
      :fandom_names,
      :rating_ids,
      :character_names,
      :relationship_names,
      :freeform_names,
      :hits,
      :kudos_count,
      :comments_count,
      :bookmarks_count,
      :sort_column,
      :sort_direction,
      :other_tag_names,
      :excluded_tag_names,
      :crossover,
      :date_from,
      :date_to,
      :words_from,
      :words_to,
      archive_warning_ids: [],
      warning_ids: [], # backwards compatibility
      category_ids: [],
      rating_ids: [],
      fandom_ids: [],
      character_ids: [],
      relationship_ids: [],
      freeform_ids: [],

      collection_ids: []
    )
  end
end
