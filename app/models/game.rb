class Game < ActiveRecord::Base

  include Utilities

  has_many :checkouts
  has_many :setups
  has_many :teardowns
  has_many :loans

  belongs_to :title
  has_one :publisher, :through => :title

  before_create :format_member_variables

  validates_format_of :barcode, with: Utilities.BARCODE_FORMAT
  validates :title, presence: true

  ST_LIMIT_COUNT = 200

  STATUS = { :active => 0, :culled => 1, :stored => 2 }

  scope :active, -> { where(:status => Game::STATUS[:active]) }
  scope :culled, -> { where(:status => Game::STATUS[:culled]) }
  scope :stored, -> { where(:status => Game::STATUS[:stored]) }

  def format_member_variables
    self.barcode.upcase!
  end

  def self.get(barcode, statuses = [Game::STATUS[:active]])
    # search for game based on barcode and event
    where(barcode: barcode.upcase, status: statuses).first
  end

  def checked_in?
    self.checkouts.where(closed: false, event: Event.current).size == 0
  end

  def loaned_in?
    self.loans.where(closed: false, event: Event.current).size == 0
  end

  def active?
    self.status == Game::STATUS[:active]
  end

  def culled?
    self.status == Game::STATUS[:culled]
  end

  def stored?
    self.status == Game::STATUS[:stored]
  end

  def name
    self.title ? self.title.title : "Title(#{self.title_id}) Not Found"
  end

  def full_name
    "#{self.barcode} - #{self.name}"
  end

  def by
    self.title ? self.title.publisher.name : "Publisher(Title: #{self.title_id}) Not Found"
  end

  def valuable?
    self.title ? self.title.valuable : false
  end

  def checked_out?
    self.checkouts.where(event: Event.current, closed: false).size > 0
  end

  def open_checkout
    self.checkouts.where(event: Event.current, closed: false).limit(1).first
  end

  def loaned?
    self.loans.where(event: Event.current, closed: false).size > 0
  end

  def current_loan
    loans = self.loans.where(event: Event.current, closed: false)
    if loans.size == 1
      loans.first
    end
  end

  def self.added_during_show(event)
    where("games.created_at::date between (?::date - '2 day'::interval) and (?::date + '2 day'::interval)", event.start_date, event.end_date).includes(:title, title: :publisher).order('titles.title asc')
  end

  def self.culled_during_show(event)
    where("status = ? and games.updated_at::date between (?::date - '2 day'::interval) and (?::date + '2 day'::interval)", Game::STATUS[:culled], event.start_date, event.end_date).includes(:title, title: :publisher).order('titles.title asc')
  end

  def self.search(title, publisher, valuable, checked, loaned, group)
    title = title.gsub(/tag:([^\s]{1,})[\s]?/i, '').strip if title
    publisher = publisher.gsub(/tag:([^\s]{1,})[\s]?/i, '').strip if publisher

    if Utilities.BARCODE_FORMAT.match(title) && !/[a-z]+/.match(title) && /\d+/.match(title)
      result = where(barcode: title.upcase)
    else
      result = self
      if title.present?
        result = result.where(title: Title.search(title))
      end
      if publisher.present?
        result = result.joins(:title).where("titles.publisher_id IN (?)", Publisher.search(publisher).select(:id))
      end
    end

    result = result.includes(title: :publisher)

    if valuable
      result = result.where(title: Title.where(valuable: true))
    end
    if checked
      result = result.includes(:checkouts).references(:checkouts).merge(Checkout.where(closed: false, event: Event.current))
    end
    if loaned
      if group.present?
        result = result.includes(:loans).references(:loans).merge(Loan.where(closed: false, group: group, event: Event.current))
      else
        result = result.includes(:loans).references(:loans).merge(Loan.where(closed: false, event: Event.current))
      end
    end
    result.where(status: Game::STATUS[:active])
  end

  def cull_game
    if self.checked_out?
      self.open_checkout.return
    end

    self.update(status: Game::STATUS[:culled])
    "#{name} successfully culled!"
  end

  def toggle_storage_status
    if self.checked_out?
      self.open_checkout.return
    end

    # If already stored, switch to active
    if self.status == Game::STATUS[:stored]
      self.update(status: Game::STATUS[:active])
      return {
        error: false,
        message: "#{name} successfully removed from storage!",
        removed: true
      }
    end

    # Otherwise, mark as stored and add to Teardown list
    Teardown.add_game(self.barcode)
    self.update(status: Game::STATUS[:stored])

    return {
      error: false,
      message: "#{name} successfully stored!"
    }
  end

  def info
    {
      name: self.name,
      publisher: self.by,
      barcode: self.barcode,
      valuable: self.valuable?
    }
  end

  def self.generate(params)
    game = Game.new

    game.errors.add('title', 'Title can not be blank.') if params[:title].blank?
    game.errors.add('publisher', 'Publisher can not be blank.') if params[:publisher].blank?

    unless params[:title].blank? || params[:publisher].blank?
      title = Title.find_or_create_by(title: format(params[:title]), publisher: Publisher.find_or_create_by(name: format(params[:publisher])))
      params[:title] = title
      params.delete(:publisher)

      if !title.valuable && params[:valuable]
        title.update(valuable: true)
      end

      params.delete(:valuable)

      game.update(params)
    end

    if !game.errors || game.errors.messages.blank? 
      Setup.where(event: Event.current).add_new_game(game)
    end

    game
  end

  def self.format(str)
    str.strip.split(' ').map(&:capitalize).join(' ')
  end

  def self.copies_as_csv
    placeholder = SecureRandom.uuid.downcase.gsub('-', '')
    csv = ["Title,Publisher,Barcode,Valuable"]
    games = where(status: Game::STATUS[:active])
              .joins(:title, title: [:publisher])
              .select("regexp_replace(initcap(regexp_replace(lower(titles.title), '''', '#{placeholder}')), '#{placeholder}', '''', 'i' ) as name, initcap(publishers.name) as publisher, games.barcode, titles.valuable")
              .order('lower(titles.title)').map do |db_row|
      "\"#{db_row[:name]}\",\"#{db_row[:publisher]}\",#{db_row[:barcode]},#{db_row[:valuable]}"
    end

    csv.concat(games).join("\n")
  end

  def self.storage_copies_as_csv
    placeholder = SecureRandom.uuid.downcase.gsub('-', '')
    csv = ["Title,Publisher,Barcode,Valuable"]
    games = where(status: Game::STATUS[:stored])
              .joins(:title, title: [:publisher])
              .select("regexp_replace(initcap(regexp_replace(lower(titles.title), '''', '#{placeholder}')), '#{placeholder}', '''', 'i' ) as name, initcap(publishers.name) as publisher, games.barcode, titles.valuable")
              .order('lower(titles.title)').map do |db_row|
      "\"#{db_row[:name]}\",\"#{db_row[:publisher]}\",#{db_row[:barcode]},#{db_row[:valuable]}"
    end

    csv.concat(games).join("\n")
  end

  def self.copy_available(title)
    self.where(title: title).any?(&:checked_in?)
  end

  def self.random_game()
    game = self.active.order("RANDOM()").first

    {
      title: game.name,
      available: self.copy_available(game.title.id),
      checkouts: game.checkouts.for_current_event.count
    }
  end

  def self.count_remaining_from(table)
    connection.execute(<<-SQL
        select count(*) as games_left from (#{sql_remaining_from(table)}) g
      SQL
    ).first['games_left'].to_i
  end

  def self.remaining_from(table)
    games_count = count_remaining_from(table)
    games_left = []
    if games_count <= ST_LIMIT_COUNT
      games_left = connection.execute(sql_remaining_from(table)).to_a
    end

    {
      games_count: games_count,
      games_left: games_left
    }
  end

  def self.sql_remaining_from(table)
    <<-SQL
      select g.barcode, initcap(lower(t.title)) as title, initcap(lower(p.name)) as publisher
      from games g
      inner join titles t on t.id = g.title_id
      inner join publishers p on p.id = t.publisher_id
      left join (select game_id from #{table} where event_id = #{Event.current.id}) st on st.game_id = g.id
      where
        g.status = #{Game::STATUS[:active]}
        and st.game_id is null
      order by 2, 1
    SQL
  end

  def self.missing_games
    events = Event.last_three_shows
    one_show = events.first
    two_show = events.second
    three_show = events.third

    connection.execute(<<-SQL
        select
          g.*, initcap(lower(t.title)) as title, initcap(lower(p.name)) as publisher
          from (
            select distinct
              g.barcode, g.title_id, g.created_at::date as created_at
              ,case when count(case when s.event_id = #{three_show.id} and s.game_id is not null then 1 end) > 0 then 'x' end as three_show_setup
              ,case when count(case when td.event_id = #{three_show.id} and td.game_id is not null then 1 end) > 0 then 'x' end as three_show_teardown
              ,case when count(case when s.event_id = #{two_show.id} and s.game_id is not null then 1 end) > 0 then 'x' end as two_show_setup
              ,case when count(case when td.event_id = #{two_show.id} and td.game_id is not null then 1 end) > 0 then 'x' end as two_show_teardown
              ,case when count(case when s.event_id = #{one_show.id} and s.game_id is not null then 1 end) > 0 then 'x' end as one_show_setup
              ,case when count(case when td.event_id = #{one_show.id} and td.game_id is not null then 1 end) > 0 then 'x' end as one_show_teardown
              ,count(distinct case when s.event_id between #{three_show.id} and #{one_show.id} and s.game_id is not null then s.event_id else null end) as setups
              ,count(distinct case when td.event_id between #{three_show.id} and #{one_show.id} and td.game_id is not null then td.event_id else null end) as teardowns
            from
              games g
            left join setups s on s.game_id = g.id
            left join teardowns td on td.game_id = g.id
            where
              g.status = #{Game::STATUS[:active]}
              and g.created_at::date <= '#{three_show.start_date}'
            group by 1, 2, 3
          ) g
          inner join titles t on t.id = g.title_id
          inner join publishers p on p.id = t.publisher_id
        where
          setups + teardowns < 4
          and (one_show_setup is null and one_show_teardown is null)
        order by lower(t.title), lower(p.name)
      SQL
    )
  end

end
