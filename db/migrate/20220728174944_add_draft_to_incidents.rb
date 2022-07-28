class AddDraftToIncidents < ActiveRecord::Migration[7.0]
  def change
    add_column :incidents, :draft, :boolean, default: false
  end
end
