require "test_helper"

class PaginationHelperTest < ActiveSupport::TestCase
  include PaginationHelper

  test "shows the first and last three pages on long lists" do
    assert_equal [1, 2, 3, nil, 77, 78, 79], compact_page_numbers(WillPaginate.PageNumber(1), 79)
    assert_equal [1, 2, 3, nil, 77, 78, 79], compact_page_numbers(79, 79)
  end

  test "shows nearby pages with bounded output far from either end" do
    assert_equal [1, 2, 3, nil, 49_999, 50_000, 50_001, nil, 99_998, 99_999, 100_000],
      compact_page_numbers(50_000, 100_000)
  end

  test "shows one missing page instead of a gap" do
    assert_equal [1, 2, 3, 4, 5, 6, 7], compact_page_numbers(1, 7)
  end
end
