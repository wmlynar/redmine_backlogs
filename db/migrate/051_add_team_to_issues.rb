class AddTeamToIssues < ActiveRecord::Migration
  def self.up
    unless ActiveRecord::Base.connection.column_exists?(:issues, :rbteam_id)
      add_column :issues, :rbteam_id, :integer
    end
  end

  def self.down
    remove_column :issues, :rbteam_id
  end
end
