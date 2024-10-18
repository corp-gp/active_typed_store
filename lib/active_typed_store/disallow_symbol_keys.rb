# frozen_string_literal: true

module ActiveTypedStore
  class SymbolKeysDisallowed < StandardError; end

  module DisallowSymbolKeys
    def self.call!(hash)
      return unless hash.is_a?(Hash)

      hash.default_proc ||= proc { |_hash, key| raise(SymbolKeysDisallowed, "Symbol keys are not allowed `#{key.inspect}`") if key.is_a?(Symbol) }
      hash.each_value { call!(_1) }
    end
  end
end
