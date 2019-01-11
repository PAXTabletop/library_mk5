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

  APPROVAL_MAP = {
    # 'normalizedtitle' => 'name',
    'roborally' => {
      handle: 'drain'
    },
    '' => {
      handle: 'warp',
      message: ''
    },
    'smashup' => {
      handle: 'el_draco',
      message: 'Robot/Zombies are OP. -El Draco'
    },
    'smallworld' => {
      handle: 'gundabad'
    },
    'theduke' => {
      handle: 'frisky',
      message: 'Frisky watches this checkout with awe and reverence!'
    }
  }

  HALF_DAY = 15.hours

  def self.longest_checkout_time_today(offset)
    start_time = (Time.now - HALF_DAY).strftime('%Y-%m-%d %H:%M:%S')
    minimum_time = self.where(closed: false)
                     .where(
                       "(check_out_time - '#{Checkout.connection.quote(offset)} hours'::interval) > ?",
                       start_time
                     ).minimum(:check_out_time).to_i

    difference = minimum_time == 0 ? 0 : Time.now - minimum_time

    Time.at(difference).utc.strftime('%H:%M:%S')
  end

  def self.longest_checkout_game_today(offset)
    start_time = (Time.now - HALF_DAY).strftime('%Y-%m-%d %H:%M:%S')
    min_checkout = self.where(closed: false).where(
                       "(check_out_time - '#{Checkout.connection.quote(offset)} hours'::interval) > ?",
                       start_time
                     ).order(:check_out_time).first
    if min_checkout
      min_game = Game.find(min_checkout.game_id)
      min_game_checkout = {
        min_checkout: min_checkout,
        min_game: min_game.name
      }
    end
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

  def self.longest
    self.where(event: Event.current, return_time: nil).order(:updated_at).limit(5)
  end

  def approval_tag
    title_text = self.game.name
    title_text = title_text.gsub(' ', '').downcase
    if APPROVAL_MAP.key?(title_text) && Event.current.is_pax
      approval = APPROVAL_MAP[title_text]
      name = approval[:handle]
      display_name = name.split('_').map(&:capitalize).join(' ')

      message = approval[:message]
      if message.nil? || message.size == 0
        message = "#{display_name} approves of this checkout!"
      end

      "<img width=\"25px\" height=\"25px\" src=\"/assets/images/#{name}.jpg\"></img>&nbsp;#{message}"
    end
  end

  def hours_played
    if return_time
      (return_time - check_out_time).to_i
    else
      DateTime.now.to_i - check_out_time.to_i
    end
  end

  def self.current_as_csv
    placeholder = SecureRandom.uuid.downcase.gsub('-', '')
    csv = ['CheckedOut,Returned,AttendeeId,Title,Publisher,GameBarcode']
    checkouts = joins(:attendee, game: [title: [:publisher]])
                  .select(
                    'checkouts.check_out_time',
                    'checkouts.return_time',
                    'attendees.barcode as a_barcode',
                    "regexp_replace(initcap(regexp_replace(lower(titles.title), '''', '#{placeholder}')), '#{placeholder}', '''', 'i' ) as title",
                    'initcap(publishers.name) as publisher',
                    'games.barcode as g_barcode'
                  ).where(event: Event.current)
                  .order(check_out_time: :asc).map do |checkout|
      "\"#{checkout[:check_out_time]}\",\"#{checkout[:return_time]}\",#{checkout[:a_barcode]},\"#{checkout[:title]}\",\"#{checkout[:publisher]}\",#{checkout[:g_barcode]}"
    end

    csv.concat(checkouts).join("\n")
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
