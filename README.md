# unicorn\_relay

## Description

The executable `unicorn_relay` contained in this gem allows you to supervise
unicorn via runit by relaying signals to it while keep running under
supervision and also handles the necessary work for handling pids, pid files,
etc.

## Usage

You can start `unicorn_relay` in your runit run script like this:

```
#!/bin/sh

# your ruby GC configuration variables: export UNICORN_GC=…
export PID_FILE="/some/where/pids/unicorn.pid"

cd "/some/where"
exec 2>&1
exec chpst -u my_user bundle exec unicorn_relay unicorn -c config/unicorn_config.rb
```

In your `unicorn_config.rb` configuration file you have to handle tearing down
an eventual old unicorn master when a new worker starts by calling
`UnicornRelay::Teardown#perform` as shown here:

```
before_fork do |server, worker|
  UnicornRelay::Teardown.new(
    pid_file: '/some/where/pids/unicorn.pid.oldbin',
    server:   server
  ).perform
end
```

The following signals will just be relayed to the forked unicorn processes:

```
HUP
USR1
USR2
TTIN
TTOU
WINCH
```

These signals will shutdown the supervised unicorn process:

```
QUIT
TERM
INT
```

In order to shutdown unicorn `unicorn_relay` just relays the `INT` and `QUIT`
signals, but changes the `TERM` signal to `QUIT` and then waits for the forked
processes to finish.

Now you can stop unicorn gracefully with the command 

```
sv stop SERVICE
```

or w/o grace by executing:

```
sv interrupt SERVICE
```

If you run

```
sv 2 SERVICE
```

a new unicorn master is forked that is still controlled by the currently
running and supervised `unicorn_relay` script. The latter enables you to load
new code into your running app with a rolling restart behaviour, that is
without interruptions of service.

## Author

[Florian Frank](mailto:flori@ping.de)

## License

This software is licensed under the Apache 2.0 license.
