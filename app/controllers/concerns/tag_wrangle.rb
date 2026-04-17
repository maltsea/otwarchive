module TagWrangle
  extend ActiveSupport::Concern

  def wrangle
    authorize :wrangling, :read_access? if logged_in_as_admin?

    @page_subtitle = ts("%{tag_name} - Wrangle", tag_name: @tag.name)
    @counts = {}
    @tag.child_types.map { |t| t.underscore.pluralize.to_sym }
      .each do |tag_type|
      @counts[tag_type] = @tag.send(tag_type).count
    end

    show = params[:show]
    if %w[fandoms characters relationships freeforms sub_tags mergers].include?(show)
      params[:sort_column] = "name" unless valid_sort_column(params[:sort_column], "tag")
      params[:sort_direction] = "ASC" unless valid_sort_direction(params[:sort_direction])
      sort = params[:sort_column] + " " + params[:sort_direction]
      # add a secondary sorting key when the main one is not discerning enough
      sort += ", name ASC" if sort.include?("suggested") || sort.include?("taggings_count_cache")
      # this makes sure params[:status] is safe
      status = params[:status]
      @tags = if %w[unfilterable canonical synonymous unwrangleable].include?(status)
                @tag.send(show).reorder(sort).send(status).paginate(page: params[:page], per_page: ArchiveConfig.ITEMS_PER_PAGE)
              elsif status == "unwrangled"
                @tag.unwrangled_tags(
                  params[:show].singularize.camelize,
                  params.permit!.slice(:sort_column, :sort_direction, :page)
                )
              else
                @tag.send(show).reorder(sort).paginate(page: params[:page], per_page: ArchiveConfig.ITEMS_PER_PAGE)
              end
    end
  end

  def mass_update
    authorize :wrangling if logged_in_as_admin?

    params[:page] = "1" if params[:page].blank?
    params[:sort_column] = "name" unless valid_sort_column(params[:sort_column], "tag")
    params[:sort_direction] = "ASC" unless valid_sort_direction(params[:sort_direction])
    options = { show: params[:show], page: params[:page], sort_column: params[:sort_column], sort_direction: params[:sort_direction], status: params[:status] }

    error_messages = []
    notice_messages = []

    # make tags canonical if allowed
    if params[:canonicals].present? && params[:canonicals].is_a?(Array)
      saved_canonicals = []
      not_saved_canonicals = []
      tags = Tag.where(id: params[:canonicals])

      tags.each do |tag_to_canonicalize|
        if tag_to_canonicalize.update(canonical: true)
          saved_canonicals << tag_to_canonicalize
        else
          not_saved_canonicals << tag_to_canonicalize
        end
      end

      error_messages << ts("The following tags couldn't be made canonical: %{tags_not_saved}", tags_not_saved: not_saved_canonicals.collect(&:name).join(", ")) unless not_saved_canonicals.empty?
      notice_messages << ts("The following tags were successfully made canonical: %{tags_saved}", tags_saved: saved_canonicals.collect(&:name).join(", ")) unless saved_canonicals.empty?
    end

    # remove associated tags
    if params[:remove_associated].present? && params[:remove_associated].is_a?(Array)
      saved_removed_associateds = []
      not_saved_removed_associateds = []
      tags = Tag.where(id: params[:remove_associated])

      tags.each do |tag_to_remove|
        if @tag.remove_association(tag_to_remove.id)
          saved_removed_associateds << tag_to_remove
        else
          not_saved_removed_associateds << tag_to_remove
        end
      end

      error_messages << ts("The following tags couldn't be removed: %{tags_not_saved}", tags_not_saved: not_saved_removed_associateds.collect(&:name).join(", ")) unless not_saved_removed_associateds.empty?
      notice_messages << ts("The following tags were successfully removed: %{tags_saved}", tags_saved: saved_removed_associateds.collect(&:name).join(", ")) unless saved_removed_associateds.empty?
    end

    # wrangle to fandom(s)
    error_messages << ts("There were no Fandom tags!") if params[:fandom_string].blank? && params[:selected_tags].is_a?(Array) && !params[:selected_tags].empty?
    if params[:fandom_string].present? && params[:selected_tags].is_a?(Array) && !params[:selected_tags].empty?
      canonical_fandoms = []
      noncanonical_fandom_names = []
      fandom_names = params[:fandom_string].split(",").map(&:squish)

      fandom_names.each do |fandom_name|
        if (fandom = Fandom.find_by_name(fandom_name)).try(:canonical?)
          canonical_fandoms << fandom
        else
          noncanonical_fandom_names << fandom_name
        end
      end

      if canonical_fandoms.present?
        saved_to_fandoms = Tag.where(id: params[:selected_tags])

        saved_to_fandoms.each do |tag_to_wrangle|
          canonical_fandoms.each do |fandom|
            tag_to_wrangle.add_association(fandom)
          end
        end

        canonical_fandom_names = canonical_fandoms.collect(&:name)
        options[:fandom_string] = canonical_fandom_names.join(",")
        notice_messages << ts("The following tags were successfully wrangled to %{canonical_fandoms}: %{tags_saved}", canonical_fandoms: canonical_fandom_names.join(", "), tags_saved: saved_to_fandoms.collect(&:name).join(", ")) unless saved_to_fandoms.empty?
      end

      error_messages << ts("The following names are not canonical fandoms: %{noncanonical_fandom_names}.", noncanonical_fandom_names: noncanonical_fandom_names.join(", ")) if noncanonical_fandom_names.present?
    end

    flash[:notice] = notice_messages.join("<br />").html_safe unless notice_messages.empty?
    flash[:error] = error_messages.join("<br />").html_safe unless error_messages.empty?

    redirect_to url_for({ controller: :tags, action: :wrangle, id: params[:id] }.merge(options))
  end
end
