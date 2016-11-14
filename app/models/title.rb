class Title < ActiveRecord::Base

  has_many :games

  belongs_to :publisher

  def self.active
    where('id in (select title_id from games where culled = false)')
  end

  def self.search(search)
    search = search.strip if search

    if search
      search_str = search.size > 1 ? "%#{search}%" : "#{search}%"
      result = where('lower(title) like lower(?)', search_str)
    else
      result = where(nil)
    end

    result
  end

end
