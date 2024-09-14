# frozen_string_literal: true

module ActiveTypedStore
  module Store
    def typed_store(store_attribute, &)
      attrs = Attrs.new(store_attribute)
      attrs.instance_eval(&)

      store_accessor store_attribute, attrs.fields
      include attrs.store_module
    end
  end
end
