class Publisher < ActiveRecord::Base

  has_many :titles

  def self.active
    where('id in (select publisher_id from titles where id in (select title_id from games where status = ?))', Game::STATUS[:active])
    .order('lower(name) asc')
  end

  def self.search(search)
    search_txt = normalize_search_text(search)
    return where(nil) if search_txt.empty?

    if unaccent_available?
      search_str = search_txt.size > 1 ? "%#{search_txt}%" : "#{search_txt}%"
      where("#{normalized_name_sql} like ?", search_str)
    else
      matching_ids = pluck(:id, :name).select do |id, name|
        normalized_name = normalize_search_text(name)
        search_txt.size > 1 ? normalized_name.include?(search_txt) : normalized_name.start_with?(search_txt)
      end.map(&:first)

      where(id: matching_ids)
    end
  end

  def self.normalize_search_text(text)
    I18n.transliterate(text.to_s).downcase.gsub(/[^a-z0-9]+/, '')
  end

  def self.normalized_name_sql
    "regexp_replace(lower(unaccent(coalesce(name, ''))), '[^a-z0-9]+', '', 'g')"
  end

  def self.unaccent_available?
    return @unaccent_available unless @unaccent_available.nil?

    @unaccent_available = connection.select_value("SELECT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'unaccent')").to_s == 't'
  rescue ActiveRecord::StatementInvalid
    @unaccent_available = false
  end

  def active_titles
    self.titles.joins(:games).where(games: { status: Game::STATUS[:active] }).distinct('lower(regexp_replace(title, \' \', \'\'))')
  end
end
