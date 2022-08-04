class CardNumberToPatron < ActiveRecord::Migration[7.0]
  def change
    add_column :patrons, :card_number, :string
  end
end
