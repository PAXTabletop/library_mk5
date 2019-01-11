class ChangeColumnName < ActiveRecord::Migration
  def change
  	rename_column :titles, :likely_tournament, :valuable
  end
end
