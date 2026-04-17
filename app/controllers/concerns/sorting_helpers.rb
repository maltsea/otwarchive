module SortingHelpers
  extend ActiveSupport::Concern

  def valid_sort_column(param, model = "work")
    allowed = {
      "work" => %w[author title date created_at word_count hit_count],
      "tag" => %w[name created_at taggings_count_cache uses],
      "prompt" => %w[fandom created_at prompter],
      "claim" => %w[created_at claimer]
    }[model.to_s.downcase]
    param.present? && allowed.include?(param.to_s.downcase)
  end

  def set_sort_order
    @sort_column = (valid_sort_column(params[:sort_column], "prompt") ? params[:sort_column] : "id")
    @sort_direction = (valid_sort_direction(params[:sort_direction]) ? params[:sort_direction] : "DESC")
    params[:sort_direction] = "DESC" if params[:sort_direction].present? && !valid_sort_direction(params[:sort_direction])
    @sort_order = @sort_column + " " + @sort_direction
  end

  def valid_sort_direction(param)
    param.present? && %w[asc desc].include?(param.to_s.downcase)
  end

  def flash_search_warnings(result)
    if result.respond_to?(:error) && result.error
      flash.now[:error] = result.error
    elsif result.respond_to?(:notice) && result.notice
      flash.now[:notice] = result.notice
    end
  end
end
