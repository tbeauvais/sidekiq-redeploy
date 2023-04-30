# Sidekiq Redeploy

The sidekiq-redeploy gem is a sidekiq launcher that allows you to redeploy a new version of your Ruby application in a container without a full container deploy.

Key Points:
* Encourages the separation of the build process from deployment
* Deploys in seconds
* Pluggable handlers to detect redeploy (File, S3, Artifactory, etc..)

![image](https://user-images.githubusercontent.com/121275/235370300-b1430140-e8de-4641-840e-016d97050df5.png)


Example application can be found [here](https://github.com/tbeauvais/puma-redeploy-test-app)
See related [puma-redeploy](https://github.com/tbeauvais/puma-redeploy) gem

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

The `sidekiq-loader` is a cli used to start Sidekiq in a child process and monitor for application updates.

```shell
Usage: sidekiq-loader [options]
    -a, --app-dir=DIR                [Required] Location of application directory.
    -w, --watch=WATCH                [Required] Location of watch file (file or s3 location).
    -y, --watch-delay INTEGER        [Optional] Specify the number of seconds between checking watch file. Defaults to 30.
    -d, --[no-]deploy  [FLAG]        [Optional] Deploy archive on app startup. Defaults to true.
    -s, --sidekiq-app [PATH|DIR]     [Optional] Location of application to pass to sidekiq.
```

For example this will start the launcher using a S3 watch file.
```shell
bundle exec sidekiq-loader -a /app -w s3://puma-test-app-archives/watch.me
```

In the example above the `watch.me` contents would look like the following. In this case the `test_app_0.0.3.zip` must exist in the `puma-test-app-archives` S3 bucket.
```shell
s3://puma-test-app-archives/test_app_0.0.3.zip
```

You can optionally use the `-s` option to specify the application file for sidekiq to run. This is useful when running a Sinatra app.
```shell
bundle exec sidekiq-loader -a /app -w s3://puma-test-app-archives/watch.me -s ./app.rb
```
### Signals
Signals can be used to send commands to the sidekiq-loader. The following signals are supported. Also see https://github.com/sidekiq/sidekiq/wiki/Signals. 

For example you can shell into your container and issue a signal using the `kill` command.
```shell
kill -USR2 pid
```

* USR2 - This signal will trigger a restart of the Sidekiq process. The Sidekiq process will be first issues a `TSTP` quiet signal, and then a `TERM` signal. This is useful in a non-production environment if you want to shell into the container, modify code, and the restart Sidekiq.
* TERM,INT - This signal will first issue a `TERM` signal to Sidekiq (giving it time to shutdown), and then shutdown sidekiq-loader. 
* TTIN - This signal will be sent to Sidekiq which will print backtraces for all threads to STDOUT.

## Development

After checking out the repo, run `bundle` to install dependencies. Then, run `rake spec` to run the tests and `rake rubocop` to check for rubocop offences.

To install this gem onto your local machine, run the following. **Note** - You must add any new files to git first.

```text
bundle exec rake install
sidekiq-redeploy 0.1.0 built to pkg/sidekiq-redeploy-0.1.0.gem.
sidekiq-redeploy (0.1.0) installed.
```

To release a new version, update the version number in `version.rb`, and then run the Release GitHub action.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tbeauvais/sidekiq-redeploy. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/tbeauvais/sidekiq-redeploy/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Sidekiq::Redeploy project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/tbeauvais/sidekiq-redeploy/blob/main/CODE_OF_CONDUCT.md).
