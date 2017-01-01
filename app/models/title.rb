class Title < ActiveRecord::Base

  has_many :games

  belongs_to :publisher

  def self.active
    where('id in (select title_id from games where culled = false)')
  end

  def self.search(search)
    search = search.strip.gsub(/\s/, '') if search

    if search
      search_str = search.size > 1 ? "%#{search}%" : "#{search}%"
      result = where('lower(regexp_replace(title, \' \', \'\')) like lower(?)', search_str)
    else
      result = where(nil)
    end

    result
  end

  def self.copies_as_csv
    csv = ['Title,Publisher,LikelyTournament,Count']
    titles = joins(:games, :publisher).where(games: { culled: false })
               .select('titles.title, publishers.name, titles.likely_tournament, games.id')
               .group(:title, :name, :likely_tournament).order('lower(titles.title)').count('games.id').map do |title_map|
      title = title_map.first.first
      pub = title_map.first.second
      likely = title_map.first.third
      copies = title_map.second
      "\"#{title}\",\"#{pub}\",#{likely},#{copies}"
    end

    csv.concat(titles).join("\n")
  end

end
