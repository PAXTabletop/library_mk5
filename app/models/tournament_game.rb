class TournamentGame < ActiveRecord::Base

  def self.active
    where(deleted: false)
  end

end
