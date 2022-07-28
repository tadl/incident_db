class AddCreatedAndEditByToIncidents < ActiveRecord::Migration[7.0]
  def change
    add_column :incidents, :created_by, :string
    add_column :incidents, :last_edit_by, :string  
  end
end
