# WaitForIt

[![Build Status](https://travis-ci.org/zombocom/wait_for_it.svg?branch=master)](https://travis-ci.org/zombocom/wait_for_it)

Spawns processes and waits for them so you can integration test really complicated things with determinism. For inspiration behind why you should use something like this check out my talk [Testing the Untestable](https://www.youtube.com/watch?v=QHMKIHkY1nM). You can test long running processes such as webservers, or features that require concurrency or libraries that use global configuration.

Don't add `sleep` to your tests, instead...

![](https://media.giphy.com/media/RL9YUXgD6a3du/giphy.gif)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wait_for_it'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install wait_for_it

## Usage

> For actual usage examples check out the [specs](https://github.com/zombocom/wait_for_it/blob/master/spec/wait_for_it_spec.rb).

This library spawns processes (sorry, doesn't work on windows) and instead of sleeping a predetermined time to wait for that process to do something it reads in a log file until certain outputs are received. For example if you wanted to test booting up a puma webserver, manually when you start it you might get this output

```sh
$ bundle exec puma
[5322] Puma starting in cluster mode...
[5322] * Version 2.15.3 (ruby 2.3.0-p0), codename: Autumn Arbor Airbrush
[5322] * Min threads: 5, max threads: 5
[5322] * Environment: development
[5322] * Process workers: 2
[5322] * Preloading application
[5322] * Listening on tcp://0.0.0.0:3000
[5322] Use Ctrl-C to stop
[5322] - Worker 0 (pid: 5323) booted, phase: 0
[5322] - Worker 1 (pid: 5324) booted, phase: 0
```

So you can see that when `booted` makes its way to the stdout we know it has fully launched and now we can start to use this running process. To do the same thing using this library we could

```ruby
require 'wait_for_it'

WaitForIt.new("bundle exec puma", wait_for: "booted") do |spawn|
  # ...
end
```

> NOTE: If you don't use the block syntax you must call `cleanup` on the object, otherwise you may have stray files or process around after you code exits. I recommend calling it in an `ensure` block of code.

Your main code will wait until it receives an output of "booted" from the `bundle exec puma` command. Now the process is running, you could programatically send it a request via `$ curl http://localhost:3000/repos/new` and verify the output using helper methods. Let's say you expect this to trigger a `302` response, the log would look like

```sh
[5324] 127.0.0.1 - - [02/Feb/2016:12:35:15 -0600] "GET /repos/new HTTP/1.1" 302 - 0.0183
```

You can now assert that is found in your puma output


```ruby
WaitForIt.new("bundle exec puma", wait_for: "booted") do |spawn|
  `curl http://localhost:3000/repos/new`
  assert_equal 1, spawn.count("302")
end
# ...
spawn.cleanup
```

If you have a background thread that sporatically emits information to the logs like [Puma Worker Killer](https://github.com/schneems/puma_worker_killer), if you configure it to do a rolling restart, you could either wait for that to happen.


```ruby
WaitForIt.new("bundle exec puma", wait_for: "booted") do |spawn
  if spawn.wait("PumaWorkerKiller: Rolling Restart")
    # ...
  end
end
```

The `wait` command will return a false if it reaches a timeout before finding the output, If you prefer you can raise an exception by using `wait!` method.

You can also assert if the output contains a phrase a string or regex:

```ruby
WaitForIt.new("bundle exec puma", wait_for: "booted") do |spawn|
  spawn.contains?("PumaWorkerKiller: Rolling Restart")
end
```

You can directly read from the log if you want


```ruby
WaitForIt.new("bundle exec puma", wait_for: "booted") do |spawn|
  spawn.log.read
end
```

The `log` method returns a `Pathname` object.

## Config

You can send environment variables to your process using the `env` key

```ruby
WaitForIt.new("bundle exec puma", wait_for: "booted", env: { RACK_ENV: "production "}) do
end
```

By default redirection is performed using `" >> "` you can change the [IO redirection](http://www.tldp.org/LDP/abs/html/io-redirection.html) by setting the `redirection` key. For example if you wanted to capture STDERR in addition to stdout:

```ruby
spawn = WaitForIt.new("bundle exec puma", wait_for: "booted", redirection: "2>>") do
end
```

If you're using Bash 4 you can get STDERR and STDOUT using `"&>>"` [Stack Overflow](http://stackoverflow.com/questions/876239/how-can-i-redirect-and-append-both-stdout-and-stderr-to-a-file-with-bash).

You can change the default timeout using the `timeout` key (default is 10 seconds).

```ruby
spawn = WaitForIt.new("bundle exec puma", wait_for: "booted", timeout: 60) do
end
```

If you need an individual `wait` have a different timeout you can pass in a timeout value

```ruby
WaitForIt.new("bundle exec puma", wait_for: "booted", timeout: 60) do |spawn|
  spawn.wait("GET /repos/new", 2) # timeout after 2 seconds
end
```

## Global config

If you're doing a lot of "waiting for it" you can supply default arguments globally

```
WaitForIt.config do |config|
  config.timeout     = 60
  config.redirection = "2>>"
  config.env         = { RACK_ENV: "production"}
end
```

## Concurrency Issues

You should be aware of cases where your tests might be run concurrently. For example if you're testing something that uses a lock in postgres, when you run your tests on a CI server it may spin up multiple tests at the same time that all try to grab the same lock. Most CI servers provide unique build IDs that you could use in this case to generate unique keys. Another thing to watch out for is files, if you're tesing a process that writes a `pidfile` you probably want to do something like make a temporary directory and copy files into that directory so that multiple tests could run at the same time and not try to write to the same file.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/zombocom/wait_for_it. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

