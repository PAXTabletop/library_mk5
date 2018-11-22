# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20181122033935) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "attendees", force: true do |t|
    t.string   "barcode",    limit: 20
    t.string   "first_name"
    t.string   "last_name"
    t.boolean  "volunteer",             default: false
    t.string   "handle"
    t.integer  "event_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "id_state",   limit: 30
  end

  add_index "attendees", ["barcode"], name: "index_attendees_on_barcode", using: :btree
  add_index "attendees", ["event_id"], name: "index_attendees_on_event_id", using: :btree

  create_table "checkouts", force: true do |t|
    t.integer  "game_id"
    t.integer  "attendee_id"
    t.integer  "event_id"
    t.datetime "check_out_time"
    t.datetime "return_time"
    t.boolean  "closed",         default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "checkouts", ["attendee_id"], name: "index_checkouts_on_attendee_id", using: :btree
  add_index "checkouts", ["event_id"], name: "index_checkouts_on_event_id", using: :btree
  add_index "checkouts", ["game_id"], name: "index_checkouts_on_game_id", using: :btree

  create_table "events", force: true do |t|
    t.string   "name"
    t.string   "location"
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "current",              default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "utc_offset",           default: 0
    t.datetime "setup_computer_tz"
    t.datetime "setup_scan_games"
    t.datetime "setup_add_new_games"
    t.datetime "setup_library_server"
    t.datetime "reset_setup"
  end

  add_index "events", ["start_date"], name: "index_events_on_start_date", using: :btree

  create_table "games", force: true do |t|
    t.string   "barcode",    limit: 20
    t.integer  "title_id"
    t.integer  "status",                default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "games", ["barcode"], name: "index_games_on_barcode", using: :btree
  add_index "games", ["title_id"], name: "index_games_on_title_id", using: :btree

  create_table "groups", force: true do |t|
    t.text     "name"
    t.text     "description"
    t.boolean  "deleted",     default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "loans", force: true do |t|
    t.integer  "game_id"
    t.integer  "group_id"
    t.datetime "check_out_time"
    t.datetime "return_time"
    t.boolean  "closed",         default: false
    t.integer  "event_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "loans", ["game_id"], name: "index_loans_on_game_id", using: :btree
  add_index "loans", ["group_id"], name: "index_loans_on_group_id", using: :btree

  create_table "publishers", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "setups", force: true do |t|
    t.integer  "game_id"
    t.integer  "event_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "setups", ["event_id"], name: "index_setups_on_event_id", using: :btree
  add_index "setups", ["game_id"], name: "index_setups_on_game_id", using: :btree

  create_table "suggestions", force: true do |t|
    t.text     "title"
    t.integer  "votes",      default: 0
    t.integer  "event_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "suggestions", ["event_id"], name: "index_suggestions_on_event_id", using: :btree

  create_table "teardowns", force: true do |t|
    t.integer  "game_id"
    t.integer  "event_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "teardowns", ["event_id"], name: "index_teardowns_on_event_id", using: :btree
  add_index "teardowns", ["game_id"], name: "index_teardowns_on_game_id", using: :btree

  create_table "titles", force: true do |t|
    t.string   "title"
    t.integer  "publisher_id"
    t.boolean  "likely_tournament", default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "titles", ["publisher_id"], name: "index_titles_on_publisher_id", using: :btree

  create_table "tournament_games", force: true do |t|
    t.text     "title"
    t.integer  "quantity",   default: 0
    t.boolean  "expansion",  default: false
    t.text     "notes"
    t.boolean  "deleted",    default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "user_name"
    t.string   "password_digest"
    t.string   "remember_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
