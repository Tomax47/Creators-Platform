class CreateEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :events do |t|
      t.json :data
      t.string :source
      t.text :processing_errors
      t.timestamps
    end

    execute <<-SQL
      ALTER TABLE events ADD COLUMN status status NOT NULL DEFAULT 'pending';
    SQL
  end
end
