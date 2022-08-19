class CreateComments < ActiveRecord::Migration[7.0]
  def change
    create_table :comments do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :incident, null: false, foreign_key: true
      t.belongs_to :patron, null: false, foreign_key: true
      t.boolean :edited
      t.text :description

      t.timestamps
    end
  end
end
