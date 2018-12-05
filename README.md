# Mysql2::Instrumentation

This gem provides OpenTracing autoinstrumentation for [Mysql2](https://github.com/brianmario/mysql2).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mysql2-instrumentation'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mysql2-instrumentation

## Usage

Before creating a new Mysql2 client, add this code:

```ruby
require 'mysql2/instrumentation'

Mysql2::Instrumentation.instrument(tracer: tracer)
```

`instrument` takes an optional parameter, `:tracer`, which sets the OpenTracing
tracer to use. If one is not provided, the `OpenTracing.global_tracer` is used.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/signalfx/mysql2-instrumentation.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
