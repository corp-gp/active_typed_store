# frozen_string_literal: true

module ActiveTypedStore
  module Store
    # typed_store(:params, encrypted: true): keys are stored as is, every value is encrypted like Rails `encrypts`.
    # Options are `encrypts` options: encrypted: { deterministic: true, previous: ..., support_unencrypted_data: true }
    class EncryptedJson < CustomJson
      # value is JSON-encoded before encryption to keep its type; not encrypted value (support_unencrypted_data)
      # is returned as is, it may be not JSON
      class ValueJson < ActiveRecord::Type::Json
        def deserialize(value)
          return value unless value.is_a?(::String)

          ActiveSupport::JSON.decode(value)
        rescue JSON::ParserError
          value
        end
      end

      def initialize(scheme_options)
        super()
        @scheme_options = scheme_options
      end

      def serialize(value) = super(value.is_a?(Hash) ? value.transform_values { value_type.serialize(_1) } : value)

      def deserialize(value)
        hash = super
        hash.is_a?(Hash) ? hash.transform_values { value_type.deserialize(_1) } : hash
      end

      # deserialize(serialize(value)) gives the same as plain json, but encrypts and decrypts every value
      # on every assignment and dirty check
      def cast(value) = CUSTOM_JSON.cast(value)
      def changed_in_place?(raw_old_value, new_value) = deserialize(raw_old_value) != cast(new_value)

      # built lazily like `encrypts` does: encryption config may be not loaded yet when the model is defined
      private def value_type
        @value_type ||= ActiveRecord::Encryption::EncryptedAttributeType.new(
          scheme:    ActiveRecord::Base.send(:scheme_for, **@scheme_options),
          cast_type: ValueJson.new,
        )
      end
    end
  end
end
