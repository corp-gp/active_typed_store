# frozen_string_literal: true

require_relative "active_typed_store/version"
require_relative "active_typed_store/configuration"
require "active_support"

ActiveSupport.on_load(:active_record) do
  require_relative "active_typed_store/store"
  require_relative "active_typed_store/attrs"
  require_relative "active_typed_store/disallow_symbol_keys"

  ActiveSupport.on_load(:active_record) { extend ActiveTypedStore::Store }
end

module ActiveTypedStore
  extend ActiveTypedStore::Configurable
end
