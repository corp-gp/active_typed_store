# frozen_string_literal: true

module ActiveTypedStore
  module Store
    JSON_NOT_SERIALIZED_TYPES = [
      ActiveModel::Type::Date,
      ActiveModel::Type::DateTime,
      ActiveModel::Type::Time,
    ].freeze
    AM_TYPES_CASTER_CACHE = Hash.new { |hash, key| hash[key] = key.new }

    def typed_store(store_attribute, attrs)
      store_accessor store_attribute, attrs.keys

      attrs.each do |key, value_klass|
        key = key.to_s
        define_method(:"#{key}?") do
          read_store_attribute(store_attribute, key).present?
        end

        _setter_for_typed_store(store_attribute, key, value_klass)
        _getter_for_typed_store(store_attribute, key, value_klass)
      end
    end

    private def _setter_for_typed_store(store_attribute, key, value_klass)
      if value_klass.name.start_with?("ActiveModel::Type::")
        value_caster = AM_TYPES_CASTER_CACHE[value_klass]
        define_method(:"#{key}=") do |value|
          v = value_caster.cast(value)
          write_store_attribute(store_attribute, key, v)
          self[store_attribute].delete(key) if v.nil?
        end
      else
        define_method(:"#{key}=") do |value|
          v = value.nil? ? nil : value_klass[value]
          write_store_attribute(store_attribute, key, v)
          self[store_attribute].delete(key) if v.nil?
        end
      end
    end

    private def _getter_for_typed_store(store_attribute, key, value_klass)
      if JSON_NOT_SERIALIZED_TYPES.include?(value_klass)
        value_caster = AM_TYPES_CASTER_CACHE[value_klass]
        ivar_prev_val = :"@__ts_prev_val_#{key}"
        ivar_cache = :"@__ts_cache_#{key}"
        define_method(key) do
          val = read_store_attribute(store_attribute, key)
          return if val.nil?

          return instance_variable_get(ivar_cache) if instance_variable_get(ivar_prev_val) == val

          instance_variable_set(ivar_prev_val, val)
          instance_variable_set(ivar_cache, value_caster.cast(val))
        end
      elsif value_klass.name.start_with?("ActiveModel::Type::")
        nil # json serialized
      elsif value_klass.class.name.start_with?("Dry::Types")
        ivar_prev_val = :"@__ts_prev_val_#{key}"
        ivar_cache = :"@__ts_cache_#{key}"
        define_method(key) do
          val = read_store_attribute(store_attribute, key)

          # value_klass.value возвращает default
          # value_klass[nil] для optional типов возвращает не default-значение, а nil
          if val.nil? && value_klass.is_a?(Dry::Types::Default)
            value_klass.value
          else
            return instance_variable_get(ivar_cache) if instance_variable_get(ivar_prev_val) == val

            instance_variable_set(ivar_prev_val, val)
            instance_variable_set(ivar_cache, value_klass[val])
          end
        end
      else
        raise "type <#{value_klass}> for field '#{key}' not supported"
      end
    end
  end
end
