namespace :events do
  desc 'Store an ended event attendee count and remove its attendee records'
  task archive_attendees: :environment do
    event = Event.find(ENV.fetch('EVENT_ID'))
    event.archive_attendees!
    puts "Archived attendees for #{event.formatted_name}: #{event.attendee_count}"
  end
end