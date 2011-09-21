class CreateBuilds < ActiveRecord::Migration
  def change
    create_table :builds do |t|
      t.string :name
      t.string :version

      t.timestamps
    end
  end
end
