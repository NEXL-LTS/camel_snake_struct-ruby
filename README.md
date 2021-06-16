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
  puts result.sites[0].url # https://duckduckgo.com
  puts result.sites[1].url # https://d.tube/
  puts result.unknown # NoMethodError
  puts result['version'] # 1
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

