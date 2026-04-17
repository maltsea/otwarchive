module PagyHelpers
  extend ActiveSupport::Concern

  included do
    include Pagy::Backend
  end

  def pagy(collection, **vars)
    pagy_overflow_handler do
      super
    end
  end

  def pagy_query_result(query_result, **vars)
    pagy_overflow_handler do
      Pagy.new(
        count: query_result.total_entries,
        page: query_result.current_page,
        limit: query_result.per_page,
        **vars
      )
    end
  end

  def pagy_overflow_handler(*)
    yield
  rescue Pagy::OverflowError
    nil
  end
end
