class Game < ActiveRecord::Base

  include Utilities

  has_many :checkouts
  has_many :setups
  has_many :teardowns

  belongs_to :title

  before_create :format_member_variables

  validates_format_of :barcode, with: Utilities.BARCODE_FORMAT
  validates :title, presence: true

  def format_member_variables
    self.barcode.upcase!
  end

  def self.get(barcode)
    # search for game based on barcode and event
    where(barcode: barcode.upcase, culled: false).first
  end

  def checked_in?
    self.checkouts.where(closed: false, event: Event.current).size == 0
  end

  def name
    self.title.title
  end

  def full_name
    "#{self.barcode} - #{self.name}"
  end

  def by
    self.title.publisher.name
  end

  def tourney?
    self.title.likely_tournament
  end

  def checked_out?
    self.checkouts.where(event: Event.current, closed: false).size > 0
  end

  def self.search(search)
    search_tags = search.to_s.scan(/tag:([^\s]{1,})[\s]?/i).flatten
    search = search.gsub(/tag:([^\s]{1,})[\s]?/i, '').strip if search

    if Utilities.BARCODE_FORMAT.match(search)
      result = where(barcode: search.upcase)
    elsif search
      search_str = search.size > 1 ? "%#{search}%" : "#{search}%"
      result = where(title: Title.search(search_str))
    else
      result = where(nil)
    end

    search_tags.each do |tag|
      case tag
        when /tournament/
          result = result.where(title: Title.where(likely_tournament: true))
        when /checkedout/
          result = result.where('games.id in (select distinct game_id from checkouts where closed = false)')
      end
    end

    result.where(culled: false)
  end

  def cull_game
    if self.checkouts.where(closed: false).size == 0
      self.update(culled: true)
      'Game successfully culled!'
    else
      'Game is still checked out! Please return game before culling it.'
    end
  end

  def info
    {
      name: self.name,
      publisher: self.by,
      barcode: self.barcode,
      likely_tournament: self.tourney?
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

      if !title.likely_tournament && params[:likely_tournament]
        title.update(likely_tournament: true)
      end

      params.delete(:likely_tournament)

      game.update(params)
    end

    game
  end

  def self.format(str)
    str.strip.split(' ').map(&:capitalize).join(' ')
  end

end
