class Event < ActiveRecord::Base

  has_many :attendees
  has_many :checkouts
  has_many :loans
  has_many :suggestions

  SETUP_COMPUTER_TZ = :setup_computer_tz
  SETUP_ADD_NEW_GAMES = :setup_add_new_games
  SETUP_LIBRARY_SERVER = :setup_library_server
  SETUP_SCAN_GAMES = :setup_scan_games
  SETUP_TAGS = [SETUP_COMPUTER_TZ, SETUP_ADD_NEW_GAMES, SETUP_LIBRARY_SERVER, SETUP_SCAN_GAMES]

  def self.current
    self.all.order(start_date: :desc).first
  end

  def is_current
    self == Event.current
  end

  def short_name
    case self.name
      when /prime/i
        'west'
      when /west/i
        'west'
      when /east/i
        'east'
      when /south/i
        'south'
      when /aus/i
        'aus'
      when /dev/i
        'dev'
      when /unplugged/i
        'unplugged'
      when /geek\s*girl\s*con|ggc/i
        'geek-girl-con'
      when /emerald\s*city\s*comic\s*con|eccc/i
        'emerald-city-comic-con'
      when /chicago\s*comic\s*entertainment\s*expo|c2e2/i
        'chicago-comic-&-entertainment-expo'
      when /shux|shut\sup|sit\sdown/i
        'shux'
      else
        self.name
    end
  end

  def formatted_name
    str = "#{self.is_pax ? 'PAX ' : nil}#{self.short_name.split(/-/).map(&:capitalize).join(' ')} #{self.year}"
    if self.is_shux
      str = str.upcase
    end
    
    str
  end

  def year
    self.start_date.strftime('%Y')
  end

  def self.is_live
    current = self.current
    (current.start_date..current.end_date) === Date.today
  end

  def is_pax
    /pax/i.match self.name
  end

  def is_ggc
    /geek\s*girl\s*con|ggc/i.match self.name
  end

  def is_eccc
    /emerald\s*city\s*comic\s*con|eccc/i.match self.name
  end
  
  def is_shux
    /shux|shut\sup|sit\sdown/i.match self.name
  end

  def is_c2e2
    /chicago\s*comic\s*entertainment\s*expo|c2e2/i.match self.name
  end

  def self.one_event_ago
    self.all.order(id: :desc).second
  end

  def self.two_events_ago
    self.all.order(id: :desc).third
  end

  def self.three_events_ago
    self.all.order(id: :desc).fourth
  end

  def self.four_events_ago
    self.all.order(id: :desc).fifth
  end

  def self.last_three_shows
    self.all.where('id >= ?', self.two_events_ago.id).order(id: :desc)
  end

  def self.last_three_event_names
    events = [Event.two_events_ago, Event.one_event_ago, Event.current]
    events.compact.map { |e| e.formatted_name }.join(', ')
  end

  def setup_complete?
    !self.setup_computer_tz.nil? &&
      !self.setup_add_new_games.nil? &&
      !self.setup_library_server.nil? &&
      !self.setup_scan_games.nil?
  end

  def update_setup_tag(tag)
    tag = tag.to_sym
    if SETUP_TAGS.include?(tag)
      obj = {}
      obj[tag] = Time.now
      self.update(obj)
    end
  end

  def reset_setup_tags
    SETUP_TAGS.each do |tag|
      self.update({ tag => nil })
    end
    self.update({ reset_setup: Time.now })
  end

  def is_last_day?
    self.end_date == Date.today
  end

  def recent_event_summary
    where_clause = Event.four_events_ago ? "where e.id >= (#{Event.four_events_ago.id})" : ''

    Event.connection.execute(
      <<-SQL
        select
          e.id as event_id
          ,e.name as event
          ,count(distinct c.attendee_id) as attendees
          ,count(distinct c.id) as checkouts
          ,round(count(distinct c.id)::numeric / count(distinct c.attendee_id)::numeric, 5) as avg_co_per_attendee
        from events e
        inner join checkouts c on c.event_id = e.id
        #{where_clause}
        group by 1
        order by 1 desc
        limit 5
      SQL
    )
  end

  def games_tracking_summary
    Event.connection.execute(
      <<-SQL
        select
          count(distinct case when g.status = #{Game::STATUS[:active]} then g.id end) as active_games
          ,count(distinct case when g.status = #{Game::STATUS[:culled]} and g.updated_at::date between ('#{self.start_date}'::date - '2 day'::interval) and ('#{self.end_date}'::date + '2 day'::interval) then g.id end) as culled_during_show
          ,count(distinct case when g.created_at::date between ('#{self.start_date}'::date - '2 day'::interval) and ('#{self.end_date}'::date + '2 day'::interval) then g.id end) as added_during_show
          ,count(distinct case when s.event_id = #{self.id} then g.id end) as games_at_setup
          ,count(distinct case when t.event_id = #{self.id} then g.id end) as games_at_teardown
        from games g
        left join setups s on s.game_id = g.id
        left join teardowns t on t.game_id = g.id
      SQL
    )
  end

  def checkouts_by_title
    placeholder = SecureRandom.uuid.downcase.gsub('-', '')
    Event.connection.execute(
      <<-SQL
        select * from (
          select
            regexp_replace(initcap(regexp_replace(lower(t.title), '''', '#{placeholder}')), '#{placeholder}', '''', 'i' ) as title
            ,string_agg(distinct initcap(lower(p.name)), ', ') as publisher
            ,count(distinct c.id) as checkouts
            ,count(distinct g.id) as copies_during_show
            ,round(count(distinct c.id)::numeric / count(distinct g.id)::numeric, 1) as checkouts_per_copy
          from games g
          left join (select * from checkouts where event_id = #{self.id}) c on g.id = c.game_id
          inner join titles t on t.id = g.title_id
          inner join publishers p on p.id = t.publisher_id
          where
            g.status = #{Game::STATUS[:active]}
            or (g.status = #{Game::STATUS[:culled]} and g.updated_at::date between '#{self.start_date - 2.days}' and '#{self.end_date + 2.days}')
            or (g.status = #{Game::STATUS[:stored]} and g.updated_at::date between '#{self.start_date - 2.days}' and '#{self.end_date + 2.days}')
          group by 1
          order by 3 desc, 1, 2
        ) c
        where checkouts > 0
      SQL
    )
  end

  def checkouts_by_publisher
    Event.connection.execute(
      <<-SQL
        select
          initcap(lower(p.name)) as publisher
          ,count(distinct c.id) as checkouts
        from checkouts c
        inner join games g on g.id = c.game_id
        inner join titles t on t.id = g.title_id
        inner join publishers p on p.id = t.publisher_id
        where
          c.event_id = #{self.id}
          and (
            g.status = #{Game::STATUS[:active]}
            or (g.status = #{Game::STATUS[:culled]} and g.updated_at::date between '#{self.start_date}' and '#{self.end_date}')
            or (g.status = #{Game::STATUS[:stored]} and g.updated_at::date between '#{self.start_date}' and '#{self.end_date}')
          )
        group by 1
        order by 2 desc, 1
      SQL
    )
  end

  def event_checkout_summary
    Event.connection.execute(
      <<-SQL
        select
          coalesce(c.date, r.date) as date
          ,coalesce(c.time, r.time) as time
          ,c.checkouts
          ,r.returns
          ,case
            when coalesce(co.checkouts, 0) - coalesce(rt.returns, 0) != 0
            then coalesce(co.checkouts, 0) - coalesce(rt.returns, 0) end as outstanding_checkouts
        from
          (
          select
            to_char((c.check_out_time + '#{self.utc_offset} hours'::interval), 'YYYY-mm-DD') as date
            ,to_char((c.check_out_time + '#{self.utc_offset} hours'::interval), 'HH24:00:00') as time
            ,count(*) as checkouts
          from checkouts c
          where event_id = #{self.id} and ((c.created_at + '#{self.utc_offset} hours'::interval)::date between '#{self.start_date}' and '#{self.end_date}')
          group by 1,2
          ) c
        full join
          (
          select
            to_char((c.return_time + '#{self.utc_offset} hours'::interval), 'YYYY-mm-DD') as date
            ,to_char((c.return_time + '#{self.utc_offset} hours'::interval), 'HH24:00:00') as time
            ,count(*) as returns
          from checkouts c
          where event_id = #{self.id} and ((c.created_at + '#{self.utc_offset} hours'::interval)::date between '#{self.start_date}' and '#{self.end_date}')
          group by 1,2
          ) r
          on c.date = r.date
          and c.time = r.time
        left join
          (
          select to_char(ts.datetime, 'YYYY-mm-DD') as date,to_char(ts.datetime, 'HH24:00:00') as time, count(*) as checkouts
          from checkouts c
          left join (SELECT distinct generate_series('#{self.start_date}'::timestamp, ('#{self.end_date}'::date + '1 day'::interval)::timestamp, interval '1 hour') as datetime) AS ts
            on ts.datetime >= to_char((c.check_out_time + '#{self.utc_offset} hours'::interval), 'YYYY-mm-DD HH24:00:00')::timestamp
          where c.event_id = #{self.id}
          group by 1,2
          ) co on co.date = coalesce(c.date, r.date) and co.time = coalesce(c.time, r.time)
        left join
          (
          select to_char(ts.datetime, 'YYYY-mm-DD') as date,to_char(ts.datetime, 'HH24:00:00') as time, count(*) as returns
          from checkouts c
          left join (SELECT distinct generate_series('#{self.start_date}'::timestamp, ('#{self.end_date}'::date + '1 day'::interval)::timestamp, interval '1 hour') as datetime) AS ts
            on ts.datetime >= to_char((c.return_time + '#{self.utc_offset} hours'::interval), 'YYYY-mm-DD HH24:00:00')::timestamp
          where c.event_id = #{self.id}
          group by 1,2
          ) rt on rt.date = coalesce(c.date, r.date) and rt.time = coalesce(c.time, r.time)
        order by 1,2
      SQL
    )
  end

  # Returns the most checked-out games for an event
  #
  # @note
  #   This doesn't return fully-hydrated game objects. You'll need
  #   to add extra data to the query inside of here if you need
  #   all the data typically accessible on a game.
  #
  # @example Get the top games for the current event
  #   Event.current.top_games(1) #=> [
  #     Game<# id: 73, name: "Monopoly", times_checked_out: 20 >
  #   ]
  #
  # @param limit [Integer] how many top games to return. Defaults to 10.
  #
  # @returns [Array<Game>] array of games with id, name, and times_checked_out
  def top_games(limit=10)
    placeholder = SecureRandom.uuid.downcase.gsub('-', '')
    games = Event.connection.execute(
      <<-SQL
        select * from (
          select
            regexp_replace(initcap(regexp_replace(lower(t.title), '''', '#{placeholder}')), '#{placeholder}', '''', 'i' ) as title
            ,t.id as title_id
            ,count(distinct c.id) as checkouts
          from games g
          left join (select * from checkouts where event_id = #{self.id}) c on g.id = c.game_id
          inner join titles t on t.id = g.title_id
          where
            g.status = #{Game::STATUS[:active]}
            or (g.status = #{Game::STATUS[:culled]} and g.updated_at::date between '#{self.start_date}' and '#{self.end_date}')
            or (g.status = #{Game::STATUS[:stored]} and g.updated_at::date between '#{self.start_date}' and '#{self.end_date}')
          group by 2
          order by 3 desc,1
        ) c
        where checkouts > 0
        limit '#{Event.connection.quote(limit)}'
      SQL
    )
    games.map do |game|
      game[:available] = Game.copy_available(game["title_id"])
      game
    end
  end

end
