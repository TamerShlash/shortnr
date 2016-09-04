class CreateShortenedUris < ActiveRecord::Migration[5.0]
  def change
    create_table :shortened_uris do |t|
      t.string :key, null: false
      t.string :original_uri, null: false

      t.timestamps
    end
    add_index :shortened_uris, :key, unique: true
  end
end
