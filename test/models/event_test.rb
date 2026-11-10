require 'test_helper'

class EventTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "event name formatting uses the name and year" do
    event = Event.new(name: "PAX west", start_date: Date.new(2026, 11, 7))
    assert_equal "PAX West 2026", event.formatted_name
  end

  test "event setup is incomplete until all four tags exist" do
    event = Event.new
    assert_not event.setup_complete?
    Event::SETUP_TAGS.each { |tag| event.public_send("#{tag}=", Time.current) }
    assert event.setup_complete?
  end

end
