require "test_helper"

class PatronTest < ActiveSupport::TestCase
  test "call 911 remains visible with overlapping suspensions" do
    patron = patrons(:one)
    first = incidents(:one)
    second = incidents(:two)
    [first, second].each { |incident| incident.update_columns(published: true) }
    suspensions(:one).update!(until: Date.current + 10)
    Suspension.create!(patron:, incident: second, until: Date.current + 3, call_police: true)

    assert patron.reload.is_suspended
    assert_includes patron.full_name, "Call 911 immediately"
    assert_equal (Date.current + 10).strftime("%m/%d/%Y"), patron.suspended_until
    assert_includes Patron.currently_suspended(call_911: true), patron

    second.update_columns(published: false)
    assert_not_includes patron.reload.full_name, "Call 911"
    assert_not_includes Patron.currently_suspended(call_911: true), patron
  end
end
