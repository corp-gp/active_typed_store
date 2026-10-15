# frozen_string_literal: true

require "active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
# ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table(:test_models, force: true) do |t|
    t.json :params
    t.text :text_params
    t.json :default_params, default: {}
  end
end

ActiveRecord::Encryption.configure(
  primary_key:         "test primary key",
  deterministic_key:   "test deterministic key",
  key_derivation_salt: "test key derivation salt",
)
