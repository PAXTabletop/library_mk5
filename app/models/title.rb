class Title < ActiveRecord::Base

  has_many :games

  belongs_to :publisher

  def self.active
    where('id in (select title_id from games where status = ?)', Game::STATUS[:active])
    .order('lower(title) asc')
  end

  def self.search(search)
    search_txt = nil
    search_txt = search.strip.gsub(/\s/, '') if search

    if search_txt
      search_str = search_txt.size > 1 ? "%#{search_txt}%" : "#{search_txt}%"
      result = where('lower(regexp_replace(title, \' \', \'\', \'g\')) like lower(?)', search_str)
    else
      result = where(nil)
    end

    result
  end

  def self.titles_as_csv
    csv = ['Title,Publisher,Valuable,Count,IDnum']
    titles = joins(:games, :publisher)
               .where(games: { status: Game::STATUS[:active] })
               .select("titles.title as publishers.name as name, titles.valuable, games.id, titles.id")
               .group('titles.title', 'publishers.name', :valuable, 'titles.id')
               .count('games.id')
               .sort{ |a, b| a.first.first.downcase <=> b.first.first.downcase }
               .map do |title_map|
      title = title_map.first.first
      pub = title_map.first.second
      likely = title_map.first.third
      idnum = title_map.first.fourth
      copies = title_map.second
      "\"#{title}\",\"#{pub}\",#{likely},#{copies},#{idnum}"
    end

    csv.concat(titles).join("\n")
  end

  def self.storage_titles_as_csv
    csv = ['Title,Publisher,Valuable,Count,IDnum']
    titles = joins(:games, :publisher)
               .where(games: { status: Game::STATUS[:stored] })
               .select("titles.title as publishers.name as name, titles.valuable, games.id, titles.id")
               .group('titles.title', 'publishers.name', :valuable, 'titles.id')
               .count('games.id')
               .sort{ |a, b| a.first.first.downcase <=> b.first.first.downcase }
               .map do |title_map|
      title = title_map.first.first
      pub = title_map.first.second
      likely = title_map.first.third
      idnum = title_map.first.fourth
      copies = title_map.second
      "\"#{title}\",\"#{pub}\",#{likely},#{copies},#{idnum}"
    end

    csv.concat(titles).join("\n")
  end

  def self.total_titles_as_csv
    csv = ['Title,Publisher,Valuable,Travel Count,Storage Count,IDnum']

    # Get all titles that have either active or stored games
    titles = includes(:games, :publisher)
             .where(games: { status: [Game::STATUS[:active], Game::STATUS[:stored]] })
             .distinct
             .order('titles.title')

    titles_data = titles.map do |title|
      travel_count = title.games.where(status: Game::STATUS[:active]).count
      stored_count = title.games.where(status: Game::STATUS[:stored]).count
      "\"#{title.title}\",\"#{title.publisher.name}\",#{title.valuable},#{travel_count},#{stored_count},#{title.id}"
    end

    csv.concat(titles_data).join("\n")
  end

end