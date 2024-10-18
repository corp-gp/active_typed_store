# frozen_string_literal: true

module ActiveTypedStore
  class Configuration
    attr_accessor :hash_safety

    def initialize
      self.hash_safety = :disallow_symbol_keys
    end
  end

  module Configurable
    attr_writer :config

    def config
      @config ||= ActiveTypedStore::Configuration.new
    end

    def configure
      yield(config)
    end
  end
end
