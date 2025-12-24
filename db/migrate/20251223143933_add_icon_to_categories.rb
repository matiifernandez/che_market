class AddIconToCategories < ActiveRecord::Migration[7.1]
  def change
    add_column :categories, :icon, :string, default: "cube"

    # Migrate existing categories based on their slugs
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE categories SET icon = CASE slug
            WHEN 'yerba-mate' THEN 'herb'
            WHEN 'dulces' THEN 'honey'
            WHEN 'mates-y-bombillas' THEN 'mug'
            WHEN 'alfajores' THEN 'cookie'
            WHEN 'bebidas' THEN 'wine'
            WHEN 'snacks' THEN 'archive'
            ELSE 'cube'
          END
        SQL
      end
    end
  end
end
