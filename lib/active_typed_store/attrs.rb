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
      field = field.name
      attr_name = store_attribute

      store_module.define_method(:"#{field}?") do
        read_store_attribute(attr_name, field).present?
      end

      if type.is_a?(Symbol)
        value_caster = ActiveRecord::Type.lookup(type, **options)
        writer(attr_name, field, value_caster)
        reader(attr_name, field, value_caster, default)
      elsif type.class.name.start_with?("Dry::Types")
        writer(attr_name, field, type)
        # dry_type[nil] для optional типов возвращает не default-значение, а nil
        reader(attr_name, field, type, (type.value if type.default?))
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
      ivar_prev  = :"@__ts_prev_#{field}"
      ivar_cache = :"@__ts_cache_#{field}"
      store_module.define_method(field) do
        val = read_store_attribute(store_attribute, field)
        return instance_variable_get(ivar_cache) if instance_variable_get(ivar_prev) == val && !val.nil?

        cache_val =
          if val.nil? && !default.nil?
            is_changed = attribute_changed?(store_attribute)
            stored_value = self[store_attribute][field] = default.dup
            clear_attribute_change(store_attribute) unless is_changed
            stored_value
          elsif type.respond_to?(:cast)
            casted = type.cast(val)
            casted.eql?(val) ? val : casted
          else
            type[val]
          end

        instance_variable_set(ivar_prev, val)
        instance_variable_set(ivar_cache, cache_val)
      end
    end
  end
end
