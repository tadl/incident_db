require "test_helper"

class PrivateLoggingTest < ActiveSupport::TestCase
  test "request logging filters incident, suspension and patron fields" do
    submitted_fields = {
      "title" => "Synthetic report title",
      "location" => "Synthetic location",
      "date_of" => "2026-11-24T10:00",
      "description" => "Synthetic report description",
      "city" => "Synthetic city",
      "zip" => "00000",
      "until" => "2026-12-01",
      "call_police" => "1",
      "letter_sent" => "1",
      "code" => "synthetic-oauth-code",
      "query" => "synthetic search",
      "id" => "42"
    }
    filtered = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters).filter(submitted_fields)
    assert_equal "42", filtered.delete("id")
    assert_equal ["[FILTERED]"], filtered.values.uniq
  end
end
