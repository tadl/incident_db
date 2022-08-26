class AddEmailStatusFieldsToSuspensions < ActiveRecord::Migration[7.0]
  def change
    add_column :suspensions, :issued_email_sent, :boolean, default: false
    add_column :suspensions, :expired_email_sent, :boolean, default: false 
  end
end