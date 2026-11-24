require "test_helper"
require "base64"
require "vips"

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
    portrait = Vips::Image.black(720, 1100).write_to_buffer(".png")
    [[incident, portrait], [patron, PNG], [legacy_report, PNG]].each do |record, image|
      record.images.attach(io: StringIO.new(image), filename: "synthetic.png", content_type: "image/png")
    end

    with_google_auth(users(:one)) do
      set_viewport(width: 1280, height: 900)
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
      assert_image_preview(report_path, incident.images.first, dismiss_with: :escape)

      set_viewport(width: 756, height: 413)
      assert_image_preview(report_path, incident.images.first, dismiss_with: :escape)

      set_viewport(width: 390, height: 844)
      assert_image_preview(patrons_list_path, patron.images.first, dismiss_with: :backdrop)
      assert_image_preview(patrons_view_path(id: patron.id), patron.images.first)
      visit old_list_path
      legacy_path = old_view_path(id: legacy_report.id)
      assert_record_thumbnail_link(legacy_path)
      assert_image_preview(legacy_path, legacy_report.images.first)
    end
  end

  private

  def set_viewport(width:, height:)
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width: width, height: height, deviceScaleFactor: 1, mobile: false)
    assert_equal [width, height], page.evaluate_script("[window.innerWidth, window.innerHeight]")
  end

  def assert_record_thumbnail_link(path)
    find("a.record-image-trigger[href='#{path}']").click
    assert_current_path path
    assert_no_selector "dialog[open]"
  end

  def assert_image_preview(path, attachment, dismiss_with: :button)
    visit path
    original_path = private_attachment_path(attachment)
    thumbnail_link = "a[data-image-preview][href='#{original_path}'][target='_blank']"
    find(thumbnail_link).click

    within "dialog[open]" do
      assert_selector "img[data-image-viewer-picture][src$='#{original_path}']", visible: true
      assert_link "Open original", href: /#{Regexp.escape(original_path)}\z/
      assert_selector 'a[aria-label="Open original in a new tab"]'
      assert_selector "button:focus", text: "Close"
      case dismiss_with
      when :escape
        assert_portrait_fits_viewer
        find("button", text: "Close").send_keys(:escape)
      when :backdrop
        find("img[data-image-viewer-picture]").click
        assert_selector "button", text: "Close"
        page.driver.browser.action.move_to_location(4, 4).click.perform
      else
        click_button "Close"
      end
    end

    assert_no_selector "dialog[open]"
    assert_selector "#{thumbnail_link}:focus"
    assert_current_path path
  end

  def assert_portrait_fits_viewer
    gaps = page.evaluate_async_script(<<~JS)
      const done = arguments[0]
      // Allow the toolbar height measurement to settle after the image loads.
      requestAnimationFrame(() => requestAnimationFrame(() => {
        const dialog = document.querySelector("dialog[open]")
        const panel = dialog.getBoundingClientRect()
        const photo = document.querySelector("[data-image-viewer-picture]")
        const image = photo.getBoundingClientRect()
        done([
          image.left - panel.left,
          panel.right - image.right,
          panel.bottom - image.bottom,
          dialog.scrollHeight - dialog.clientHeight,
          dialog.scrollWidth - dialog.clientWidth,
          Math.abs(image.width / image.height - photo.naturalWidth / photo.naturalHeight)
        ])
      }))
    JS

    left, right, bottom, vertical_overflow, horizontal_overflow, aspect_ratio_error = gaps
    assert_in_delta left, right, 1
    assert_in_delta left, bottom, 1
    assert_operator bottom, :>=, 12
    assert_operator vertical_overflow, :<=, 1
    assert_operator horizontal_overflow, :<=, 1
    assert_operator aspect_ratio_error, :<, 0.01
  end
end
