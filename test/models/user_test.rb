require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "explicit roles are case-insensitive and trim configuration whitespace" do
    staff = users(:one)
    with_env("SUPER_ADMIN" => "admin@example.org, ALICE@EXAMPLE.ORG ",
      "CAN_EDIT" => " alice@example.org ", "CAN_SUSPEND" => nil) do
      assert staff.is_super_admin
      assert staff.can_edit_incident(incidents(:two))
      assert_not staff.can_suspend
      assert_not users(:two).is_super_admin
    end
  end

  test "draft viewing and deletion respect ownership and separate staff roles" do
    owner = users(:one)
    other_staff = users(:two)
    draft = incidents(:one)
    draft.assign_attributes(created_by: owner.id.to_s, published: false)
    with_env("CAN_EDIT" => nil, "SUPER_ADMIN" => nil) do
      assert owner.can_view_incident(draft)
      assert owner.can_delete_this_incident(draft)
      assert_not other_staff.can_view_incident(draft)
      assert_not other_staff.can_delete_this_incident(draft)

      draft.published = true
      assert other_staff.can_view_incident(draft)
      assert_not owner.can_delete_this_incident(draft)
    end
  end
end
