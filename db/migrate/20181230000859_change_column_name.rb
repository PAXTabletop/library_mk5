class ChangeColumnName < ActiveRecord::Migration[4.2]
  def change
  	rename_column :titles, :likely_tournament, :valuable
  end
end
