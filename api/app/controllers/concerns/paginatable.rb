module Paginatable
  extend ActiveSupport::Concern

  def paginate(collection)
    page = params.fetch(:page, 0).to_i
    size = params.fetch(:size, 50).to_i

    pagy    = Pagy::Offset.new(page: page + 1, limit: size, count: collection.count)
    records = pagy.records(collection)

    {
      content:          records,
      pageable: {
        pageNumber:     pagy.page - 1,
        pageSize:       pagy.limit,
        offset:         pagy.offset
      },
      totalPages:       pagy.pages,
      totalElements:    pagy.count,
      last:             pagy.next.nil?,
      first:            pagy.previous.nil?,
      size:             pagy.limit,
      number:           pagy.page - 1,
      numberOfElements: records.size,
      empty:            records.empty?
    }
  end
end
