class Checkout < ActiveRecord::Base

  belongs_to :game
  belongs_to :attendee
  belongs_to :event

  before_create :fill_in_fields

  validates :attendee, presence: true
  validates :game, :presence => {:message => 'Game does not exist.'}
  validates_each :game, on: :create do |record, attr, value|
    if value
      record.errors.add(attr, "#{name} is already checked out.") unless value.checked_in?
      record.errors.add(attr, "#{name} is currently loaned out to the group '#{value.current_loan.group.name}'. Please return it via the group's <a href='/loaners/group/#{value.current_loan.group.id}'>Loaners page</a> tab first.") unless value.loaned_in?
      record.errors.add(attr, 'Game does not exist.') if value.culled?
      record.errors.add(attr, "#{name} is currently in storage.") if value.stored?
    end
  end

  scope :for_current_event, -> { where(event: Event.current) }
  scope :closed, -> { where(closed: true) }
  scope :active, -> { where(closed: false) }

  HALF_DAY = 15.hours

  def fill_in_fields
    self.event = Event.current
    self.check_out_time = Time.now.utc
  end

  def self.new_checkout(params)
    Checkout.create(game: Game.get(params[:g_barcode]), attendee: Attendee.get(params[:a_barcode]))
  end

  def return
    now = Time.now.utc
    update_columns(return_time: now, closed: true, updated_at: now)
  end

  def hours_played
    if return_time
      (return_time - check_out_time).to_i
    else
      DateTime.now.to_i - check_out_time.to_i
    end
  end

  def self.current_as_csv
    csv = ['CheckedOut,Returned,AttendeeId,Title,Publisher,GameBarcode']
    checkouts = joins(:attendee, game: [title: [:publisher]])
                  .select(
                    'checkouts.check_out_time',
                    'checkouts.return_time',
                    'attendees.barcode as a_barcode',
                    'titles.title as title',
                    'publishers.name as publisher',
                    'games.barcode as g_barcode'
                  ).where(event: Event.current)
                  .order(check_out_time: :asc).map do |checkout|
      "\"#{checkout[:check_out_time]}\",\"#{checkout[:return_time]}\",#{checkout[:a_barcode]},\"#{checkout[:title]}\",\"#{checkout[:publisher]}\",#{checkout[:g_barcode]}"
    end

    csv.concat(checkouts).join("\n")
  end

  def self.purge_recommendations(gradation = 0.5, setup_scanned_only = false)
    setup_filter = if setup_scanned_only
      <<-SQL
          and not exists (
            select 1
            from games unscanned_game
            where unscanned_game.title_id = t.id
              and unscanned_game.status = 0
              and not exists (
                select 1
                from setups current_setup
                where current_setup.game_id = unscanned_game.id
                  and current_setup.event_id = #{Event.current.id}
              )
          )
      SQL
    else
      ''
    end

    Checkout.connection.execute(
      <<-SQL
        select
          t.title
          ,t.copies
          ,t.copies_created_prior
          ,t.checkouts_from_three
          ,t.checkouts_from_four
          ,t.checkouts_from_five
          ,t.latest_created_at
          ,round((copies_created_prior::numeric / copies::numeric), 2)
        from
          (
          select
            t.title as title
            ,count(distinct g.id) as copies
            ,sum(c.co_since_three) as checkouts_from_three
            ,sum(c.co_since_four) as checkouts_from_four
            ,sum(c.co_since_five) as checkouts_from_five
            ,count(distinct
              case when g.created_at::date <= '#{Event.two_events_ago.start_date}'::date then g.id
              else null
              end
            ) as copies_created_prior
            ,max(g.created_at::date) as latest_created_at
          from
            titles t
          inner join games g on g.title_id = t.id and g.status = 0
          left join (
            select
              c.game_id
              ,count(case when e.id >= #{Event.two_events_ago.id} then c.id else null end) as co_since_three
              ,count(case when e.id >= #{Event.three_events_ago.id} then c.id else null end) as co_since_four
              ,count(case when e.id >= #{Event.four_events_ago.id} then c.id else null end) as co_since_five
            from
              checkouts c
            inner join events e on e.id = c.event_id
            group by 1
          ) c on c.game_id = g.id
          where 1 = 1
          #{setup_filter}
          group by 1
          ) t
        where
          t.checkouts_from_three = 0
          and round((copies_created_prior::numeric / copies::numeric), 2) > #{gradation.round(2)}
        order by 1
      SQL
    )
  end

end
