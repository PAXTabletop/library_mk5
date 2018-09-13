class ChangeCulledToStatus < ActiveRecord::Migration
  def change
    reversible do |change|
      change.up{
        rename_column :games, :culled, :status
        change_column_default :games, :status, nil
        change_column :games, :status, 'integer USING (CASE status WHEN true THEN 1 ELSE 0 END)'
        change_column_default :games, :status, 0
      }
      change.down {
        rename_column :games, :status, :culled
        change_column_default :games, :culled, nil
        change_column :games, :culled, 'boolean USING (CASE culled WHEN 1 THEN true ELSE false END)'
        change_column_default :games, :culled, false
      }
    end
  end
end
