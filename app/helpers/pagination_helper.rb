module PaginationHelper
  def compact_page_numbers(current_page, last_page)
    current_page = current_page.to_i
    candidates = [1, 2, 3, current_page - 1, current_page, current_page + 1,
                  last_page - 2, last_page - 1, last_page]
    visible_pages = candidates.select { |page| page.between?(1, last_page) }.uniq.sort

    visible_pages.each_cons(2).each_with_object(visible_pages.first(1)) do |(before, page), numbers|
      gap = page - before
      numbers << before + 1 if gap == 2
      numbers << nil if gap > 2
      numbers << page
    end
  end
end
