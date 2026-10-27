class CreateSiteSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :site_settings do |t|
      t.string :site_name
      t.string :tagline
      t.string :contact_email
      t.string :contact_phone
      t.text :address
      t.string :logo_url
      t.string :primary_color
      t.string :footer_text
      t.boolean :maintenance_mode

      t.timestamps
    end
  end
end
