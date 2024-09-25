# ActiveTypedStore

`active_typed_store` is a lightweight (__65 lines of code__) and highly performant gem (see [benchmarks](#benchmarks))
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

### Benchmarks
compare `active_typed_store` with other gems
```ruby
#                    gem     getter  i/s                setter i/s            Lines of code
#  rails (without types):    27930.8                    660                   170
#     active_typed_store:    24318.5 - 1.15x  slower    656                   65
#        store_attribute:    23748.3 - 1.18x  slower    639                   276
#            store_model:    23324.4 - 1.20x  slower    595                   857
#              attr_json:    15541.4 - 1.80x  slower    577 - 1.14x  slower   1195
#         jsonb_accessor:    15000.1 - 1.86x  slower    626                   324
```       

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
