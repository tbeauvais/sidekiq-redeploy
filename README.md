# Sidekiq Redeploy

The sidekiq-redeploy gem is a sidekiq launcher that allows you to redeploy a new version of your Ruby application in a container without a full container deploy.

Key Points:
* Encourages the separation of the build process from deployment
* Deploys in seconds
* Plugable handlers to detect redeploy (File, S3, Artifactory, etc..)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-redeploy'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install sidekiq-redeploy

## Usage

TODO: Write usage instructions here...

## Development

After checking out the repo, run `bundle` to install dependencies. Then, run `rake spec` to run the tests and `rake rubocop` to check for rubocop offences.

To install this gem onto your local machine, run the following. **Note** - You must add any new files to git first.

```text
bundle exec rake install
sidekiq-redeploy 0.1.0 built to pkg/sidekiq-redeploy-0.1.0.gem.
sidekiq-redeploy (0.1.0) installed.
```

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/sidekiq-redeploy. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/sidekiq-redeploy/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Sidekiq::Redeploy project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/sidekiq-redeploy/blob/master/CODE_OF_CONDUCT.md).
