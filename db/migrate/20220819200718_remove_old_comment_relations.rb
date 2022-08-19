class RemoveOldCommentRelations < ActiveRecord::Migration[7.0]
  def change
    remove_reference :comments, :user
    remove_reference :comments, :incident
    remove_reference :comments, :patron
  end
end
