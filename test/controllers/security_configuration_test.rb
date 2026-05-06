require "test_helper"

class SecurityConfigurationTest < ActionDispatch::IntegrationTest
  test "mutating controllers verify csrf tokens" do
    [IncidentsController, PatronsController, CommentsController, AdminController, OldController].each do |controller|
      skips = controller._process_action_callbacks.select do |callback|
        callback.kind == :skip && callback.filter == :verify_authenticity_token
      end

      assert_empty skips, "#{controller.name} should not skip CSRF verification"
    end
  end

  test "omniauth request phase is post only" do
    assert_equal [:post], OmniAuth.config.allowed_request_methods
  end
end
