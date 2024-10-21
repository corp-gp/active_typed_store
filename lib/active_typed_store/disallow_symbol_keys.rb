# frozen_string_literal: true

module ActiveTypedStore
  class SymbolKeysDisallowed < StandardError; end

  DEFAULT_PROC =
    proc do |_hash, key|
      raise(SymbolKeysDisallowed, "Symbol keys are not allowed `#{key.inspect}`") if key.is_a?(Symbol)
    end

  module DisallowSymbolKeys
    def self.call!(hash)
      return unless hash.is_a?(Hash)

      hash.default_proc ||= DEFAULT_PROC
      hash.each_value { call!(_1) }
    end
  end

  # Same interface as ActiveRecord::Store::HashAccessor
  # Optimized by using object.read_attribute(attribute) instead of object.send(attribute)
  class StoreHashAccessor
    def self.read(object, attribute, key)
      prepare(object, attribute)
      object.read_attribute(attribute)[key]
    end

    def self.write(object, attribute, key, value)
      prepare(object, attribute)
      object.read_attribute(attribute)[key] = value if value != object.read_attribute(attribute)[key]
    end

    def self.prepare(object, attribute)
      object.public_send :"#{attribute}=", {} unless object.read_attribute(attribute)
    end
  end
end
