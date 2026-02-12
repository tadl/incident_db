class CreateViolationSummaries < ActiveRecord::Migration[7.2]
  def change
    create_table :violation_summaries do |t|
      t.text :description, null: false

      t.belongs_to :incident, null: false, foreign_key: true
      t.belongs_to :patron, null: false, foreign_key: true

      t.timestamps
    end

    # Enforce one summary per incident/patron pair
    add_index :violation_summaries,
              [:incident_id, :patron_id],
              unique: true,
              name: "index_violation_summaries_on_incident_and_patron"
  end
end
