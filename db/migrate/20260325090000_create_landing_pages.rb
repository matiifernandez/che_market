# frozen_string_literal: true

class CreateLandingPages < ActiveRecord::Migration[7.1]
  def change
    create_table :landing_pages do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :meta_title
      t.text :meta_description
      t.string :hero_title
      t.text :hero_subtitle
      t.string :hero_cta_text
      t.string :hero_cta_url
      t.jsonb :blocks, null: false, default: []
      t.boolean :published, null: false, default: false

      t.timestamps
    end

    add_index :landing_pages, :slug, unique: true
    add_index :landing_pages, :published
  end
end
