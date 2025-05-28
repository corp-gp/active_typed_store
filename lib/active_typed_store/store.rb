# frozen_string_literal: true

module ActiveTypedStore
  module Store
    def typed_store(store_attribute, &block)
      attrs = Attrs.new(store_attribute)
      attrs.instance_eval(&block)

      store_accessor store_attribute, attrs.fields.map {_1[:name] }

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

      after_initialize do
        attrs.fields.each do |field|
          if field[:default].present? && read_store_attribute(store_attribute, field[:name]).nil?
            public_send(field[:name])
          end
        end
      end

    end
  end
end