module TagSearch
  extend ActiveSupport::Concern

  def search
    options = params[:tag_search].present? ? tag_search_params : {}
    options.merge!(page: params[:page]) if params[:page].present?
    @search = TagSearchForm.new(options)
    @page_subtitle = ts("Search Tags")

    return if params[:tag_search].blank?

    @page_subtitle = ts("Tags Matching '%{query}'", query: options[:name]) if options[:name].present?

    @tags = @search.search_results
    flash_search_warnings(@tags)
  end
end
