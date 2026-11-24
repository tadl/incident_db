class CreateIncidentPatrons < ActiveRecord::Migration[8.1]
  def up
    create_table :incident_patrons do |t|
      t.references :incident, null: false, index: false, foreign_key: true
      t.references :patron, null: false, foreign_key: true
      t.index [:incident_id, :patron_id], unique: true
    end

    execute <<~SQL
      INSERT INTO incident_patrons (incident_id, patron_id)
      SELECT incident_id, patron_id
      FROM (
        SELECT incident_id, patron_id FROM violations
        UNION
        SELECT incident_id, patron_id FROM violation_summaries
        UNION
        SELECT incident_id, patron_id FROM suspensions
      ) AS historical_links
      INNER JOIN incidents ON incidents.id = historical_links.incident_id
      INNER JOIN patrons ON patrons.id = historical_links.patron_id
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Removing incident patrons would delete links created under the new policy"
  end
end
