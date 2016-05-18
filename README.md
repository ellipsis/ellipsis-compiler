# Ellipsis-compiler [![Build Status][travis-image]][travis-url] [![Documentation status][docs-image]][docs-url] [![Latest tag][tag-image]][tag-url] [![Gitter chat][gitter-image]][gitter-url]

Configuration file compiler

**Warning: This project is in an early alpha stage. Use at own risk!**

Ellipsis-Compiler is a compiler for configuration files. It makes it possible
to use logic in any config file. This allows you to make dynamic
configurations, even if this is normally not supported.

### Features
- ...

### Install

**Requirements:** [Ellipsis][ellipsis]

```bash
# With ellipsis installed
$ ellipsis install ellipsis-compiler

# Without ellipsis installed
$ curl -Ls ellipsis.sh | PACKAGES='ellipsis-compiler' sh
```

The `.ellipsis/bin` folder should be added to your path. If it isn't you will
need to symlink `.ellipsis/bin/ellipsis-compiler` to a folder that is in your path.

### Usage

Basic usage:

```bash
$ ellipsis-compiler $input-file $output-file
```
If the output file is omitted, `$input-file.out` will be used.

U can alter the behavior of the compiler by setting some env. variables.
TODO

#### Syntax
Ellipsis-Compiler uses specially formatted comments for its syntax. This will
preserve syntax highlighting/checks and makes it possible to have a files that
also work if they aren't compiled.

By default the `#` symbol is used to indicate comments, but this can be altered
by setting the `$EC_COMMENT` variable. Lines with a special meaning are
indicated with a prompt like string `_>`. This can be altered by setting the
`$EC_PROMPT` variable.

###### Example
```bash

```

##### include (include_raw)
Include a file, or include a file without processing (include_raw).

```bash
#_> include test_file.conf
#_> include_raw raw_config.conf
```

##### if (then, else, elif)
Use the if,then,else/elif construction to alter compilation output.

```bash
# TODO
```

##### raw
Perform a raw shell command and write output to the compiled file.

```bash
# TODO
```

##### write (>)
Write a string to the output file.

```bash
conf.settings=example
#_> write #_> put the magic string in the file
conf.server=test

# Using the short form, ideal for indenting lines
#_> if [ ! -f test_file ]; then
#_>     > conf.settings=default_file
#_> else
#_>     > conf.settings=test_file
#_> fi
```

##### msg
Print a message to stdout, to inform a user about something.

```bash
conf.settings=example
conf.server=test
#_> msg Config is using server 'test'

conf.name=dev
```

##### fail
Stop compilation and display the given message.

```bash
#_> if [ ! -f test_file ]; then
#_>     fail Could not compile!
#_> else
        conf.settings=test_file
#_> fi
```

### Docs
Please consult the [docs][docs-url] for more information.

Specific parts that could be off interest:
- ...

### Development
Pull requests welcome! New code should follow the [existing style][style-guide]
(and ideally include [tests][bats]).

Suggest a feature or report a bug? Create an [issue][issues]!

### Author(s)
You can thank [these][contributors] people for all there hard work.

### License
Ellipsis-compiler is open-source software licensed under the [MIT license][mit-license].

[travis-image]: https://img.shields.io/travis/ellipsis/ellipsis-compiler.svg
[travis-url]:   https://travis-ci.org/ellipsis/ellipsis-compiler
[docs-image]:   https://readthedocs.org/projects/ellipsis-compiler/badge/?version=master
[docs-url]:     http://ellipsis-compiler.readthedocs.org/en/master
[tag-image]:    https://img.shields.io/github/tag/ellipsis/ellipsis-compiler.svg
[tag-url]:      https://github.com/ellipsis/ellipsis-compiler/tags
[gitter-image]: https://badges.gitter.im/ellipsis/ellipsis.svg
[gitter-url]:   https://gitter.im/ellipsis/ellipsis

[ellipsis]:     https://github.com/ellipsis/ellipsis

[style-guide]:  https://google-styleguide.googlecode.com/svn/trunk/shell.xml
[bats]:         https://github.com/sstephenson/bats
[issues]:       http://github.com/ellipsis/ellipsis-compiler/issues

[contributors]: https://github.com/ellipsis/ellipsis-compiler/graphs/contributors
[mit-license]:  http://opensource.org/licenses/MIT
