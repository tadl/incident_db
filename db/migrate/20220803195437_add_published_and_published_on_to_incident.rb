class AddPublishedAndPublishedOnToIncident < ActiveRecord::Migration[7.0]
  def change
    add_column :incidents, :published, :boolean, default: false
    add_column :incidents, :published_on, :datetime
  end
end
