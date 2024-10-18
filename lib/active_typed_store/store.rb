# frozen_string_literal: true

module ActiveTypedStore
  module Store
    def typed_store(store_attribute, &)
      attrs = Attrs.new(store_attribute)
      attrs.instance_eval(&)

      store_accessor store_attribute, attrs.fields

      define_method store_attribute do
        case ActiveTypedStore.config.hash_safety
        when :disallow_symbol_keys
          super().tap { ActiveTypedStore::DisallowSymbolKeys.call!(_1) }
        else
          super()
        end
      end

      include attrs.store_module
    end
  end
end
