class Title < ActiveRecord::Base

  has_many :games

  belongs_to :publisher

end
