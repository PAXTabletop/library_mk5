class Loan < ActiveRecord::Base

  belongs_to :group
  belongs_to :game

end
