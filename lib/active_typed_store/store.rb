# frozen_string_literal: true

module ActiveTypedStore
  module Store
    class CustomJson < ActiveRecord::Type::Json
      def changed_in_place?(raw_old_value, new_value)
        deserialize(raw_old_value) != new_value.as_json
      end
    end

    def typed_store(store_attribute, &)
      attrs = Attrs.new(store_attribute)
      attrs.instance_eval(&)

      # for redefined self._default_attributes
      def self.type_for_column(connection, column) # rubocop:disable Lint/NestedMethodDefinition
        return ActiveTypedStore::Store::CustomJson.new if column.name == "params"

        super
      end
      store_accessor store_attribute, attrs.fields

      if ActiveTypedStore.config.hash_safety == :disallow_symbol_keys
        define_method store_attribute do
          super().tap { ActiveTypedStore::DisallowSymbolKeys.call!(_1) }
        end

        define_method :store_accessor_for do |_store_attribute|
          ActiveTypedStore::StoreHashAccessor
        end

        private :store_accessor_for
      end

      include attrs.store_module
    end
  end
end
