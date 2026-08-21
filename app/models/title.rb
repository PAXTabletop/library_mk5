class Title < ActiveRecord::Base

  has_many :games

  belongs_to :publisher

  def self.active
    where('id in (select title_id from games where status = ?)', Game::STATUS[:active])
    .order('lower(title) asc')
  end

  def self.search(search)
    search_txt = normalize_search_text(search)
    return where(nil) if search_txt.empty?

    if unaccent_available?
      search_str = search_txt.size > 1 ? "%#{search_txt}%" : "#{search_txt}%"
      where("#{normalized_title_sql} like ?", search_str)
    else
      matching_ids = pluck(:id, :title).select do |id, title|
        normalized_title = normalize_search_text(title)
        search_txt.size > 1 ? normalized_title.include?(search_txt) : normalized_title.start_with?(search_txt)
      end.map(&:first)

      where(id: matching_ids)
    end
  end

  def self.normalize_search_text(text)
    I18n.transliterate(text.to_s).downcase.gsub(/[^a-z0-9]+/, '')
  end

  def self.normalized_title_sql
    "regexp_replace(lower(unaccent(coalesce(title, ''))), '[^a-z0-9]+', '', 'g')"
  end

  def self.unaccent_available?
    return @unaccent_available unless @unaccent_available.nil?

    @unaccent_available = connection.select_value("SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'unaccent')").to_s == 't'
  rescue ActiveRecord::StatementInvalid
    @unaccent_available = false
  end

  def self.titles_as_csv
    csv = ['Title,Publisher,Valuable,Count,IDnum']
    titles = joins(:games, :publisher)
               .where(games: { status: Game::STATUS[:active] })
               .select("titles.title, publishers.name as name, titles.valuable, games.id, titles.id")
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
               .select("titles.title, publishers.name as name, titles.valuable, games.id, titles.id")
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
    csv = ['Title,Publisher(s),Valuable,Travel Count,Storage Count,IDnum(s)']

    games = Game.where(status: [Game::STATUS[:active], Game::STATUS[:stored]])
                .includes(title: :publisher)
    normalized = ->(value) { value.to_s.downcase }
    title_groups = games.group_by do |game|
      normalized.call(game.title.title)
    end

    titles_data = title_groups.map do |_key, grouped_games|
      display_game = grouped_games.min_by { |game| [normalized.call(game.title.title), game.title_id] }
      title = display_game.title
      publishers = grouped_games.map { |game| game.title.publisher.name }.uniq.sort_by { |name| normalized.call(name) }
      travel_count = grouped_games.count { |game| game.status == Game::STATUS[:active] }
      stored_count = grouped_games.count { |game| game.status == Game::STATUS[:stored] }
      valuable = grouped_games.any? { |game| game.title.valuable }
      title_ids = grouped_games.map(&:title_id).uniq.sort
      [normalized.call(title.title), "\"#{title.title}\",\"#{publishers.join(', ')}\",#{valuable},#{travel_count},#{stored_count},\"#{title_ids.join(', ')}\""]
    end
    .sort_by { |title_data| title_data.first(2) }
    .map(&:last)

    csv.concat(titles_data).join("\n")
  end

end
