# frozen_string_literal: true

require_relative 'active_typed_store/version'
require 'active_support'

ActiveSupport.on_load(:active_record) do
  require_relative 'active_typed_store/store'
  ::ActiveRecord::Base.extend(ActiveTypedStore::Store)
end
