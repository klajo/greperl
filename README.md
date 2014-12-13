greperl
=======

This is an experiment in trying to convert Erlang tuples into
something that can be read and manipulated using tools such as `grep`
or `awk`.

Let us assume we have this file:

```erlang
{foo, [{ip,"127.0.0.1"},
       {port,4711},
       {opts, [no_delay,
               {active, true}]}]}.
```

We can then convert that like this:

```bash
$ ./bin/greperl my_file
foo.ip="127.0.0.1"
foo.port=4711
foo.opts=no_delay
foo.opts.active=true
```

`greperl` can be used both from a shell through the `bin/greperl`
escript, or the Erlang API.  For command line options, see:

```bash
$ ./bin/greperl -h
Usage: greperl [-h] [-s <separator>] [--no-quote-strings] <file>

  -h, --help          show help
  -s, --separator     set key-value separator
  --no-quote-strings  do not quote strings
  <file>              name of file which can be read using file:consult/1
```
