# ActiveTypedStore

`active_typed_store` is a lightweight (__105 lines of code__) and highly performant gem (see [benchmarks](#benchmarks))
designed to help you store and manage typed data in JSON format within database.
This gem provides a simple, yet powerful way to ensure that your JSON data cast
to specific types, enabling more structured and reliable use of JSON fields in your Rails models.

You can use `ActiveRecord Types` for simplicity or `Dry Types` for more advanced features such as
constraints and type composition. You can also combine both approaches
in the same model to get the best of both worlds.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "active_typed_store"
```

## Usage

### Using [ActiveRecord Types](https://api.rubyonrails.org/classes/ActiveRecord/Type.html)

```ruby
class Model < ActiveRecord::Base
  typed_store(:params) do # params - the name of the store
    attr :task_id,   :integer
    attr :name,      :string
    attr :notify_at, :datetime
    attr :asap,      :boolean, default: false
    attr :settings,  :json
  end
end

m = Model.first
m.task_id = "123" # string
m.task_id # => 123, int
m.task_id? # => true, value.present? under the hood
m.asap? # => false
m.asap = "yes"
m.asap # => true
m.asap? # => true
```

`attr(name, type, options)`

- `name` the name of the accessor to the store
- `type` a symbol such as `:string` or `:integer`, or a type object to be used for the accessor
- `options` (optional), a hash of cast type options such as:
  - `precision`, `limit`, `scale`
  - `default` the default value to use when no value is provided. Otherwise, the default will be nil
  - `array` specifies that the type should be an array


### Using [Dry Types](https://dry-rb.org/gems/dry-types/1.7/built-in-types/)
```ruby
class Model < ActiveRecord::Base
  typed_store(:params) do
    attr :task_id,   Types::Params::Integer
    attr :name,      Types::Params::String
    attr :notify_at, Types::Params::Time
    attr :asap,      Types::Params::Bool.default(false)
    attr :email,     Types::String.constrained(format: /@/)
    attr :settings,  Types::Params::Hash
  end
end
```

### Combine ActiveRecord and Dry Types

```ruby
class Model < ActiveRecord::Base
  typed_store(:params) do
    attr :price,  :decimal, scale: 2
    attr :active, :immutable_string
    attr :email,  Types::String.constrained(format: /@/)
    attr :state,  Types::String.enum('draft', 'published', 'archived')
    attr :tariff_id, Types::Array.of(Types::Params::Integer)
  end
end
```

### Hash safety
This gem assumes you're using a database that supports structured data types, such as `json` in `PostgreSQL` or `MySQL`, and leverages Rails' [store_accessor](https://edgeapi.rubyonrails.org/classes/ActiveRecord/Store.html) under the hood. However, there’s one caveat: JSON columns use a string-keyed hash and don’t support access via symbols. To avoid unexpected errors when accessing the hash, we raise an error if a symbol is used. You can disable this behavior by setting `config.hash_safety = false`.

```ruby
class Model < ActiveRecord::Base
  typed_store(:params) do
    attr :price,  :decimal
  end
end

record = Model.new(price: 1)
record["price"] # 1
record[:price] # raises "Symbol keys are not allowed `:price` (ActiveTypedStore::SymbolKeysDisallowed)"

# initializers/active_type_store.rb
ActiveTypeStore.configure do |config|
  config.hash_safety = false # default :disallow_symbol_keys
end

record["price"] # 1
record[:price] # nil - isn't the expected behavior for most applications
```

### Benchmarks
compare `active_typed_store` with other gems
```ruby
# ruby 3.3.5 arm64-darwin24
#                    gem     getter  i/s                setter i/s            Lines of code
#     active_typed_store:    28502.2                    656                   105
#  rails (without types):    27350.5                    660                   170
#        store_attribute:    24592.2 - 1.16x  slower    639                   276
#            store_model:    22833.6 - 1.25x  slower    595                   857
#              attr_json:    14000.4 - 2.03x  slower    577 - 1.14x  slower   1195
#         jsonb_accessor:    13995.4 - 2.04x  slower    626                   324
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
