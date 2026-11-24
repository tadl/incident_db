require "test_helper"
require "base64"

class ImageViewerTest < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1280, 900]

  PNG = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aKbkAAAAASUVORK5CYII=")

  def after_teardown
    Capybara.current_session.driver.quit
    super
  end

  test "report list thumbnails navigate to records and detail images preview the private original" do
    incident = incidents(:one)
    incident.update!(published: true)
    incident_without_photo = incidents(:two)
    incident_without_photo.update!(published: true)
    patron = patrons(:one)
    legacy_report = oldreports(:one)
    [incident, patron, legacy_report].each do |record|
      record.images.attach(io: StringIO.new(PNG), filename: "synthetic.png", content_type: "image/png")
    end

    with_google_auth(users(:one)) do
      visit incidents_path
      click_button "Sign in with Google"
      assert_current_path incidents_path

      report_path = incidents_view_path(id: incident.id)
      placeholder_path = incidents_view_path(id: incident_without_photo.id)
      assert_selector "a.record-image-trigger[href='#{report_path}'] img"
      assert_selector "a.record-image-trigger[href='#{placeholder_path}'] .fa-person-falling-burst"
      assert_record_thumbnail_link(placeholder_path)
      visit incidents_path
      assert_record_thumbnail_link(report_path)
      assert_image_preview(report_path, incident.images.first, escape: true)

      page.current_window.resize_to(390, 844)
      assert_operator page.evaluate_script("window.innerWidth"), :<=, 575
      assert_image_preview(patrons_list_path, patron.images.first)
      assert_image_preview(patrons_view_path(id: patron.id), patron.images.first)
      visit old_list_path
      legacy_path = old_view_path(id: legacy_report.id)
      assert_record_thumbnail_link(legacy_path)
      assert_image_preview(legacy_path, legacy_report.images.first)
    end
  end

  private

  def assert_record_thumbnail_link(path)
    find("a.record-image-trigger[href='#{path}']").click
    assert_current_path path
    assert_no_selector "dialog[open]"
  end

  def assert_image_preview(path, attachment, escape: false)
    visit path
    original_path = private_attachment_path(attachment)
    thumbnail_link = "a[data-image-preview][href='#{original_path}'][target='_blank']"
    find(thumbnail_link).click

    within "dialog[open]" do
      assert_selector "img[data-image-viewer-picture][src$='#{original_path}']", visible: true
      assert_link "Open original in a new tab", href: /#{Regexp.escape(original_path)}\z/
      assert_selector "button:focus", text: "Close"
      if escape
        find("button", text: "Close").send_keys(:escape)
      else
        click_button "Close"
      end
    end

    assert_no_selector "dialog[open]"
    assert_selector "#{thumbnail_link}:focus"
    assert_current_path path
  end
end
