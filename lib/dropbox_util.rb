module DropboxUtil

  DROPBOX_ACCESS_KEY = ''
  MSG_NO_CONFIG = 'Dropbox access is not configured. This must be configured by a system admin.'

  def self.configured?
    !DROPBOX_ACCESS_KEY.empty?
  end

  def self.backup
    # fail out if dropbox key doesn't exist
    if DROPBOX_ACCESS_KEY.size <= 0
      return {
        status: 500,
        message: MSG_NO_CONFIG
      }
    end

    client = DropboxApi::Client.new(DropboxUtil::DROPBOX_ACCESS_KEY)
    time = Time.now.to_i.to_s

    base_folder = '/pax-tt-library-backups'

    non_show_models = [Event, Game, Publisher, Title, TournamentGame, User, Group]
    non_show_models.each do |model_const|
      folder_path = "#{base_folder}/general-data-backup"

      run_backup(time, client, model_const, folder_path)
    end

    show_models = [Attendee, Checkout, Setup, Suggestion, Teardown, Loan]
    Event.last_three_shows.each do |event|
      year = event.year
      show = event.short_name
      folder_path = "#{base_folder}/show-specific-backup/#{year}/#{show}"

      show_models.each do |model_const|
        run_backup(time, client, model_const, folder_path, event)
      end
    end

    return {
      status: 200,
      message: 'Backup successfully completed!'
    }
  end

  def self.run_backup(time_str, db_client, model_const, base_folder, event = nil)
    model_name = model_const.to_s.downcase
    folder_path = "#{base_folder}/#{model_name}"
    backed_up = false

    begin
      folder = db_client.list_folder(folder_path)
    rescue
      folder = []
    end

    lu_file = nil
    lu_time = nil
    if folder.entries.size > 0
      folder.entries.each do |entry|
        matcher = (/last_updated[_]*(\d*)[.]txt/.match(entry.name))
        if matcher
          lu_time = matcher[1].to_i
          lu_file = entry.name
        end
      end
    end

    if event.nil?
      model_time = model_const.maximum(:updated_at)
    else
      model_time = model_const.where(event: event).maximum(:updated_at)
    end
    model_time ||= 0
    if !lu_file || model_time.to_i > lu_time
      json_output = get_records(model_const, event)

      if json_output.size > 0
        result = db_client.upload("#{folder_path}/#{time_str}_#{model_name}.json", json_output)
      end
      if lu_file
        db_client.delete("#{folder_path}/#{lu_file}")
      end
      db_client.upload("#{folder_path}/last_updated_#{time_str}.txt", '')
      backed_up = true
    end

    backed_up
  end

  def self.get_records(model_const, event = nil)
    if event
      records = model_const.where(event: event)
    else
      records = model_const.all
    end

    records.to_json
  end

end