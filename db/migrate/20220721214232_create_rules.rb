class CreateRules < ActiveRecord::Migration[7.0]
  def change
    create_table :rules do |t|
      t.string :track
      t.string :description
      t.boolean :legacy, default: false

      t.timestamps
    end
  end
end
