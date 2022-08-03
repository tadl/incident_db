class AddNoPatronsToIncident < ActiveRecord::Migration[7.0]
  def change
    add_column :incidents, :no_patrons, :boolean, default: false
  end
end
