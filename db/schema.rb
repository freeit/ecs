# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110303145153) do

  create_table "auths", :force => true do |t|
    t.string   "one_touch_hash"
    t.integer  "message_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "communities", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "community_messages", :force => true do |t|
    t.integer  "community_id"
    t.integer  "message_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ev_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "events", :force => true do |t|
    t.integer  "participant_id"
    t.integer  "message_id"
    t.integer  "ev_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",   :default => 0
  end

  create_table "identities", :force => true do |t|
    t.integer  "participant_id"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "membership_messages", :force => true do |t|
    t.integer  "membership_id"
    t.integer  "message_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",  :default => 0
  end

  create_table "memberships", :force => true do |t|
    t.integer  "participant_id"
    t.integer  "community_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "messages", :force => true do |t|
    t.string   "content_type"
    t.integer  "sender"
    t.text     "body"
    t.integer  "ressource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "removed",      :default => false
  end

  create_table "organizations", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "abrev"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "participants", :force => true do |t|
    t.string   "name"
    t.string   "dns"
    t.string   "email"
    t.text     "description"
    t.integer  "organization_id"
    t.datetime "ttl"
    t.boolean  "anonymous",             :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "community_selfrouting", :default => false
  end

  create_table "ressource_monitors", :force => true do |t|
    t.integer  "lock_version",    :default => 0
    t.integer  "monitor_counter", :default => 0
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ressources", :force => true do |t|
    t.string   "namespace"
    t.string   "ressource"
    t.boolean  "postroute",  :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "events",     :default => true
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

end
