class Checkout < ActiveRecord::Base

  belongs_to :game
  belongs_to :attendee
  belongs_to :event

  before_create :fill_in_fields

  validates :attendee, presence: true
  validates :game, presence: true
  validates_each :game, on: :create do |record, attr, value|
    if value
      record.errors.add(attr, 'Game is already checked out.') unless value.checked_in?
      record.errors.add(attr, 'Game does not exist.') if value.culled
    end
  end

  def self.longest_checkout_time_today(offset)
    start_time = (Time.now - 15.hours).strftime('%Y-%m-%d %H:%M:%S')
    minimum_time = self.where(closed: false)
                     .where(
                       "(check_out_time - '#{offset} hours'::interval) > ?",
                       start_time
                     ).minimum(:check_out_time).to_i

    difference = minimum_time == 0 ? 0 : Time.now - minimum_time

    Time.at(difference).utc.strftime('%H:%M:%S')
  end

  def fill_in_fields
    self.event = Event.current
    self.check_out_time = Time.now.utc
  end

  def self.new_checkout(params)
    Checkout.create(game: Game.get(params[:g_barcode]), attendee: Attendee.get(params[:a_barcode]))
  end

  def return
    self.return_time = Time.now.utc
    self.closed = true
    self.save
  end

  def self.recent
    self.where(event: Event.current, return_time: nil).order(updated_at: :desc).limit(5)
  end

  def self.purge_recommendations(gradation = 0.5)
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
            initcap(lower(t.title)) as title
            ,count(distinct g.id)	as copies
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
          inner join games g on g.title_id = t.id and g.culled = false
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
