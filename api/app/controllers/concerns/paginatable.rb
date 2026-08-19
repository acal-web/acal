module Paginatable
  extend ActiveSupport::Concern

  def paginate(collection)
    page = params.fetch(:page, 0).to_i
    size = [ params.fetch(:size, 10).to_i, 100 ].min

    count = collection.limit(200001).count
    total_count = count > 200000 ? 200000 : count

    pagy    = Pagy::Offset.new(page: page + 1, limit: size, count: total_count)
    records = pagy.records(collection)
    has_next = count > ((page + 1) * size)

    {
      content:          records,
      pageable: {
        pageNumber:     pagy.page - 1,
        pageSize:       pagy.limit,
        offset:         pagy.offset
      },
      hasNextPage:      has_next,
      totalElements:    total_count,
      totalPages:       pagy.pages,
      last:             !has_next,
      first:            pagy.previous.nil?,
      size:             pagy.limit,
      number:           pagy.page - 1,
      numberOfElements: records.size,
      empty:            records.empty?
    }
  end
end
