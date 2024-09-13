# frozen_string_literal: true

module ActiveTypedStore
  class Attrs
    attr_reader :fields, :store_module, :store_attribute

    def initialize(store_attribute)
      @store_attribute = store_attribute
      @fields = []
      @store_module = Module.new
    end

    def attr(field, type, default: nil, **options)
      @fields << field

      store_module.define_method(:"#{field}?") do
        read_store_attribute(store_attribute, field).present?
      end

      if type.is_a?(Symbol)
        value_caster = ActiveModel::Type.lookup(type, **options)
        writer(store_attribute, field, value_caster)
        reader(store_attribute, field, value_caster, default)
      elsif type.class.name.start_with?("Dry::Types")
        writer(store_attribute, field, type)
        reader(store_attribute, field, type, (type.value if type.default?))
      else
        raise "type <#{type}> for field '#{field}' not supported"
      end
    end

    private def writer(store_attribute, field, type)
      store_module.define_method(:"#{field}=") do |value|
        v = (type.respond_to?(:cast) ? type.cast(value) : type[value]) unless value.nil?
        write_store_attribute(store_attribute, field, v)
        self[store_attribute].delete(field) if v.nil?
      end
    end

    private def reader(store_attribute, field, type, default)
      ivar_prev_val = :"@__ts_prev_#{field}"
      ivar_cache = :"@__ts_cache_#{field}"
      store_module.define_method(field) do
        val = read_store_attribute(store_attribute, field)

        # dry_type.value возвращает default
        # dry_type[nil] для optional типов возвращает не default-значение, а nil
        if val.nil? && !default.nil?
          default
        else
          return instance_variable_get(ivar_cache) if instance_variable_get(ivar_prev_val) == val

          instance_variable_set(ivar_prev_val, val)
          instance_variable_set(ivar_cache, type.respond_to?(:cast) ? type.cast(val) : type[val])
        end
      end
    end
  end
end
