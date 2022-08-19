class AddFieldsToComments < ActiveRecord::Migration[7.0]
  def change
    add_column :comments, :user_id, :integer
    add_column :comments, :patron_id, :integer
    add_column :comments, :incident_id, :integer
  end
end
