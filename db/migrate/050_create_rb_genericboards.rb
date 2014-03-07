class CreateRbGenericboards < ActiveRecord::Migration
  def change
    create_table :rb_genericboards do |t|
      t.string :name
      t.text :prefilter
      t.text :rows
      t.text :cols
      t.string :elements

      t.timestamps
    end
  end
end
