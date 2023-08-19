# CamelSnakeStruct

Easily access camelCased hashes in a ruby_friendly_way.
Main focus is handling responses from APIs that use camelCased keys.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'camel_snake_struct'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install camel_snake_struct

## Usage

For once of hashes

```ruby
  result = CamelSnakeStruct.new('version' => 1, 'rubyVersion' => '2.5.0', 
                                'sites' => [{ 'url' => "https://duckduckgo.com", 'searchEngine' => true }, 
                                            { 'url' => "https://d.tube/", 'searchEngine' => false }])

  puts result.version # 1
  puts result.ruby_version # 2.5.0
  puts result['version'] # 1

  if result.sites?
    puts result.sites[0].url # https://duckduckgo.com
    puts result.sites[1].url # https://d.tube/
  end

  puts result.people? # false
  puts result.people # NoMethodError
```

Or Learning Structs

```ruby
MyLearningStruct = Class.new(CamelSnakeStruct)

result1 = MyLearningStruct.new('data' => [{ 'name' => 'Jeff' }])
puts result1.data.map(&:name) # ["Jeff"]
# never received errors key before
puts result.errors # NoMethodError

result2 = MyLearningStruct.new('errors' => ['failed to get response'])
# it remembers the shape from the first succesfull request
puts result2.data.map(&:name) # []
puts result.errors # ["failed to get response"]

MyLoadedStruct = Class.new(CamelSnakeStruct)

MyLoadedStruct.example('data' => [{ 'name' => 'Jeff' }], 'errors' => [], 'date' => { 'timezone' => 'UTC', 'unixTime' => 0})

result3 = MyLoadedStruct.new({'date' => { }})
puts result3.data # []
puts result3.errors # []
puts result3.date.timezone # nil
puts result3.date.unix_time # nil
```

Learning Structs store meta data about the shape of the hash from the examples provided.
This can be used with tapioca custom DSL compilers to generate sorbet types

```ruby
MyLoadedStruct = Class.new(CamelSnakeStruct)
MyLoadedStruct.example('data' => [{ 'name' => 'Jeff' }], 'errors' => [], 'date' => { 'timezone' => 'UTC', 'unixTime' => 0})

puts MyLoadedStruct.types_meta_data
# {"data"=>#<struct CamelSnakeStruct::Type__Meta__Data class_types=#<Set: {MyLoadedStruct::Datum}>, array=true>, "errors"=>#<struct CamelSnakeStruct::Type__Meta__Data class_types=#<Set: {}>, array=true>, "date"=>#<struct CamelSnakeStruct::Type__Meta__Data class_types=#<Set: {MyLoadedStruct::Date}>, array=false>}
```

```ruby
# typed: true

module Tapioca
  module Compilers
    class CamelSnakeStructCompiler < Tapioca::Dsl::Compiler
      extend T::Sig

      ConstantType = type_member {{ fixed: T.class_of(CamelSnakeStruct) }}

      sig { override.returns(T::Enumerable[Module]) }
      def self.gather_constants
        all_classes.select do |c| 
          c < ::CamelSnakeStruct && !c.types_meta_data.empty?
        end
      end

      sig { override.void }
      def decorate
        root.create_path(constant) do |klass|
          constant.types_meta_data.each do |name, meta_data|
            classes = meta_data.classes.to_a.map{|a| [TrueClass,FalseClass].include?(a) ? "T::Boolean" : a.to_s }.uniq
            return_type = if classes.size == 1
              classes.first.to_s
            else
              "T.any(#{classes.join(', ')})"
            end
            if meta_data.array
              klass.create_method(name.to_s, parameters: [], return_type: "T::Array[#{return_type}]")
            elsif return_type == 'NilClass' || return_type == 'String'
              klass.create_method(name.to_s, parameters: [], return_type: 'T.nilable(String)')
            else
              klass.create_method(name.to_s, parameters: [], return_type: return_type)
            end
            klass.create_method("#{name}?", parameters: [], return_type: 'T::Boolean')
          end
        end
      end
    end
  end
end
```


### Limitations

* Expects to receive a hash
* Only works with string keys
* Does not work well with keys that point to array of arrays
* expects the hash to always have the same struct for learning structs

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/camel_snake.

