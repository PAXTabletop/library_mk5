class Publisher < ActiveRecord::Base

  has_many :titles

  def self.active
    where('id in (select publisher_id from titles where id in (select title_id from games where culled = false))')
    .order('lower(name) asc')
  end

  def self.search(search)
    search = search.strip.gsub(/\s/, '') if search

    if search
      search_str = search.size > 1 ? "%#{search}%" : "#{search}%"
      result = where('lower(regexp_replace(name, \' \', \'\', \'g\')) like lower(?)', search_str)

    else
      result = where(nil)
    end

    result
  end

  def active_titles
    self.titles.joins(:games).where(games: { culled: false }).distinct('lower(regexp_replace(title, \' \', \'\'))')
  end

end
