# Opal Zeitwerk

## Community and Support
At the [Isomorfeus Project](http://isomorfeus.com) - isomorphic full stack Ruby for the web.

## TOC
<!-- TOC -->

- [Introduction](#introduction)
- [Synopsis](#synopsis)
- [File structure](#file-structure)
    - [Implicit namespaces](#implicit-namespaces)
    - [Explicit namespaces](#explicit-namespaces)
    - [Nested root directories](#nested-root-directories)
- [Usage](#usage)
    - [Setup](#setup)
    - [Autoloading](#autoloading)
    - [Eager loading](#eager-loading)
    - [Reloading](#reloading)
    - [Inflection](#inflection)
        - [Zeitwerk::Inflector](#zeitwerkinflector)
        - [Custom inflector](#custom-inflector)
    - [Ignoring parts of the project](#ignoring-parts-of-the-project)
        - [Use case: Files that do not follow the conventions](#use-case-files-that-do-not-follow-the-conventions)
    - [Edge cases](#edge-cases)
    - [Rules of thumb](#rules-of-thumb)
    - [Autoloading, explicit namespaces, and debuggers](#autoloading-explicit-namespaces-and-debuggers)
- [Pronunciation](#pronunciation)
- [Supported Opal versions](#supported-opal-versions)
- [Motivation](#motivation)
- [License](#license)

<!-- /TOC -->

<a id="markdown-introduction" name="introduction"></a>
## Introduction

Opal Zeitwerk is a port of the Ruby [Zeitwerk](https://github.com/fxn/zeitwerk) loader to Opal for autoloading ruby code in the Browser.
Autoloading reduces upfront TTI(time to interactive) for large opal projects vastly.

Given a [conventional file structure](#file-structure), Opal Zeitwerk is able to load your project's classes and modules on demand (autoloading),
or upfront (eager loading)(currently untested). You don't need to write `require` calls for your own files, rather, you can streamline your programming,
knowing that your classes and modules are available everywhere. This feature is efficient, and matches Ruby's semantics for constants.

The gem is designed so that any project, gem dependency, application, etc. can have their own independent loader, managing their own project trees,
and independent of each other. Each loader has its own configuration, inflector, and optional logger.

Internally, Opal Zeitwerk issues `require` calls exclusively using absolute path names as recorded in Opal modules registry.

Differences to Ruby Zeitwerk:
- no logging (to keep asset size small and performance high)
- no gem specific support: GemInflector, for_gem, etc.

  These don't make so much sense, as Opal Zeitwerk works on the global Opal.modules registry in the Browser, not the filesystem.
- Zeitwerk::Loader.set_autoloads_in_dir is public, so it can be called from lazy loaded code, after updating Opal.modules.
- There are no threads in javascript so thread support has been removed.
- Tests don't run yet.
<a id="markdown-synopsis" name="synopsis"></a>
## Synopsis

Main generic interface:

```ruby
loader = Zeitwerk::Loader.new
loader.push_dir(...)
loader.setup # ready!
```

The `loader` variable can go out of scope. Zeitwerk keeps a registry with all of them, and so the object won't be garbage collected.

You can reload if you want to:

```ruby
loader = Zeitwerk::Loader.new
loader.push_dir(...)
loader.enable_reloading # you need to opt-in before setup
loader.setup
...
loader.reload
```

and you can eager load all the code:

```ruby
loader.eager_load
```

It is also possible to broadcast `eager_load` to all instances:

```ruby
Zeitwerk::Loader.eager_load_all
```

<a id="markdown-file-structure" name="file-structure"></a>
## File structure

To have a file structure Zeitwerk can work with, just name files and directories after the name of the classes and modules they define:

```
lib/my_gem.rb         -> 'my_gem'         -> MyGem
lib/my_gem/foo.rb     -> 'my_gem/foo'     -> MyGem::Foo
lib/my_gem/bar_baz.rb -> 'my_gem/bar_baz' -> MyGem::BarBaz
lib/my_gem/woo/zoo.rb -> 'my_gem/woo/zoo' -> MyGem::Woo::Zoo
```
Second column shows how files are registered in Opals modules registry. These paths in the registry are relevant for Opal Zeitwerk running in the Browser.
Every directory configured with `push_dir` acts as root namespace. There can be several of them. For example, given

```ruby
loader.push_dir("app/models")
loader.push_dir("app/controllers")
```

Zeitwerk understands that their respective files and subdirectories belong to the root namespace:

```
app/models/user                        -> User
app/controllers/admin/users_controller -> Admin::UsersController
```

<a id="markdown-implicit-namespaces" name="implicit-namespaces"></a>
### Implicit namespaces

Directories without a matching Ruby file get modules autovivified automatically by Zeitwerk. For example, in

```
app/controllers/admin/users_controller -> Admin::UsersController
```

`Admin` is autovivified as a module on demand, you do not need to define an `Admin` class or module in an `admin.rb` file explicitly.

<a id="markdown-explicit-namespaces" name="explicit-namespaces"></a>
### Explicit namespaces

Classes and modules that act as namespaces can also be explicitly defined, though. For instance, consider

```
app/models/hotel         -> Hotel
app/models/hotel/pricing -> Hotel::Pricing
```

There, `app/models/hotel` defines `Hotel`, and thus Zeitwerk does not autovivify a module.

The classes and modules from the namespace are already available in the body of the class or module defining it:

```ruby
class Hotel < ApplicationRecord
  include Pricing # works
  ...
end
```

An explicit namespace must be managed by one single loader. Loaders that reopen namespaces owned by other projects are responsible for loading their constants before setup.

<a id="markdown-nested-root-directories" name="nested-root-directories"></a>
### Nested root directories

Root directories should not be ideally nested, but Zeitwerk supports them because in Rails, for example, both `app/models` and `app/models/concerns` belong to the autoload paths.

Zeitwerk detects nested root directories, and treats them as roots only. In the example above, `concerns` is not considered to be a namespace below `app/models`. For example, the file:

```
app/models/concerns/geolocatable
```

should define `Geolocatable`, not `Concerns::Geolocatable`.

<a id="markdown-usage" name="usage"></a>
## Usage

Add to the Gemfile:
```
gem 'opal', '>= 1.3.0'
gem 'opal-zeitwerk', '~> 0.2.3'
```

And to your loader of opal code:
```
require 'zeitwerk'
```

<a id="markdown-setup" name="setup"></a>
### Setup
Files must be included in the compiled asset by:
```
require_tree 'some_dir', autoload: true
```
And added to the loader by:
```
loader.push_dir('some_dir')
```
The loader here requires the part of the path as it would appear in Opal.modules.
If `require_tree` is called from a sub directory, the path from the root as it would appear in Opal.modules has to be prepended for push_dir.

Loaders are ready to load code right after calling `setup` on them:

```ruby
loader.setup
```

This method is synchronized and idempotent.

Customization should generally be done before that call. In particular, in the generic interface you may set the root module paths from which you want to load files:

```ruby
loader.push_dir(...)
loader.push_dir(...)
loader.setup
```

Zeitwerk works internally only with absolute paths.

<a id="markdown-autoloading" name="autoloading"></a>
### Autoloading

After `setup`, you are able to reference classes and modules from the project without issuing `require` calls for them. They are all available everywhere,
autoloading loads them on demand. This works even if the reference to the class or module is first hit in client code, outside your project.

If autoloading a file does not define the expected class or module, Zeitwerk raises `Zeitwerk::NameError`, which is a subclass of `NameError`.

<a id="markdown-eager-loading" name="eager-loading"></a>
### Eager loading (untested)

Zeitwerk instances are able to eager load their managed files:

```ruby
loader.eager_load
```

That skips [ignored files and directories](#ignoring-parts-of-the-project), and you can also tell Zeitwerk that certain files or directories are autoloadable, but should not be eager loaded:

```ruby
db_adapters = "#{__dir__}/my_gem/db_adapters"
loader.do_not_eager_load(db_adapters)
loader.setup
loader.eager_load # won't eager load the database adapters
```

Eager loading is synchronized and idempotent.

If eager loading a file does not define the expected class or module, Zeitwerk raises `Zeitwerk::NameError`, which is a subclass of `NameError`.

If you want to eager load yourself and all dependencies using Zeitwerk, you can broadcast the `eager_load` call to all instances:

```ruby
Zeitwerk::Loader.eager_load_all
```

This may be handy in top-level services, like web applications.

Note that thanks to idempotence `Zeitwerk::Loader.eager_load_all` won't eager load twice if any of the instances already eager loaded.

<a id="markdown-reloading" name="reloading"></a>
### Reloading (untested)

Zeitwerk is able to reload code, but you need to enable this feature:

```ruby
loader = Zeitwerk::Loader.new
loader.push_dir(...)
loader.enable_reloading # you need to opt-in before setup
loader.setup
...
loader.reload
```

There is no way to undo this, either you want to reload or you don't.

Enabling reloading after setup raises `Zeitwerk::Error`. Attempting to reload without having it enabled raises `Zeitwerk::ReloadingDisabledError`.

Generally speaking, reloading is useful while developing running services like web applications. Gems that implement regular libraries, so to speak, or services running in testing or production environments, won't normally have a use case for reloading. If reloading is not enabled, Zeitwerk is able to use less memory.

Reloading removes the currently loaded classes and modules and resets the loader so that it will pick whatever is in the file system now.

It is important to highlight that this is an instance method. Don't worry about project dependencies managed by Zeitwerk, their loaders are independent.

In order for reloading to be thread-safe, you need to implement some coordination. For example, a web framework that serves each request with its own thread may have a globally accessible RW lock. When a request comes in, the framework acquires the lock for reading at the beginning, and the code in the framework that calls `loader.reload` needs to acquire the lock for writing.

On reloading, client code has to update anything that would otherwise be storing a stale object. For example, if the routing layer of a web framework stores controller class objects or instances in internal structures, on reload it has to refresh them somehow, possibly reevaluating routes.

<a id="markdown-inflection" name="inflection"></a>
### Inflection

Each individual loader needs an inflector to figure out which constant path would a given file or directory map to. Zeitwerk ships with two basic inflectors.

<a id="markdown-zeitwerkinflector" name="zeitwerkinflector"></a>
#### Zeitwerk::Inflector

This is a very basic inflector that converts snake case to camel case:

```
user             -> User
users_controller -> UsersController
html_parser      -> HtmlParser
```

The camelize logic can be overridden easily for individual basenames:

```ruby
loader.inflector.inflect(
  "html_parser"   => "HTMLParser",
  "mysql_adapter" => "MySQLAdapter"
)
```

The `inflect` method can be invoked several times if you prefer this other style:

```ruby
loader.inflector.inflect "html_parser" => "HTMLParser"
loader.inflector.inflect "mysql_adapter" => "MySQLAdapter"
```

Overrides need to be configured before calling `setup`.

There are no inflection rules or global configuration that can affect this inflector. It is deterministic.

Loaders instantiated with `Zeitwerk::Loader.new` have an inflector of this type, independent of each other.

<a id="markdown-custom-inflector" name="custom-inflector"></a>
#### Custom inflector

The inflectors that ship with Zeitwerk are deterministic and simple. But you can configure your own:

```ruby
# frozen_string_literal: true

class MyInflector < Zeitwerk::Inflector
  def camelize(basename, abspath)
    if basename =~ /\Ahtml_(.*)/
      "HTML" + super($1, abspath)
    else
      super
    end
  end
end
```

The first argument, `basename`, is a string with the basename of the file or directory to be inflected. In the case of a file, without extension. In the case of a directory, without trailing slash. The inflector needs to return this basename inflected. Therefore, a simple constant name without colons.

The second argument, `abspath`, is a string with the absolute path to the file or directory in case you need it to decide how to inflect the basename. Paths to directories don't have trailing slashes.

Then, assign the inflector:

```ruby
loader.inflector = MyInflector.new
```

This needs to be done before calling `setup`.

<a id="markdown-ignoring-parts-of-the-project" name="ignoring-parts-of-the-project"></a>
### Ignoring parts of the project

Zeitwerk ignores automatically any file or directory whose name starts with a dot, and any files that do not have extension ".rb".

However, sometimes it might still be convenient to tell Zeitwerk to completely ignore some particular Ruby file or directory. That is possible with `ignore`, which accepts an arbitrary number of strings or `Pathname` objects, and also an array of them.

You can ignore file names, directory names, and glob patterns. Glob patterns are expanded when they are added and again on each reload.

Let's see some use cases.

<a id="markdown-use-case-files-that-do-not-follow-the-conventions" name="use-case-files-that-do-not-follow-the-conventions"></a>
#### Use case: Files that do not follow the conventions

Let's suppose that your gem decorates something in `Kernel`:

```ruby
# lib/my_gem/core_ext/kernel.rb

Kernel.module_eval do
  # ...
end
```

That file does not define a constant path after the path name and you need to tell Zeitwerk:

```ruby
kernel_ext = "#{__dir__}/my_gem/core_ext/kernel.rb"
loader.ignore(kernel_ext)
loader.setup
```

You can also ignore the whole directory:

```ruby
core_ext = "#{__dir__}/my_gem/core_ext"
loader.ignore(core_ext)
loader.setup
```

<a id="markdown-edge-cases" name="edge-cases"></a>
### Edge cases

A class or module that acts as a namespace:

```ruby
# trip.rb
class Trip
  include Geolocation
end

# trip/geolocation.rb
module Trip::Geolocation
  ...
end
```

has to be defined with the `class` or `module` keywords, as in the example above.

For technical reasons, raw constant assignment is not supported:

```ruby
# trip.rb
Trip = Class.new { ... }  # NOT SUPPORTED
Trip = Struct.new { ... } # NOT SUPPORTED
```

This only affects explicit namespaces, those idioms work well for any other ordinary class or module.

<a id="markdown-rules-of-thumb" name="rules-of-thumb"></a>
### Rules of thumb

1. Different loaders should manage different directory trees. It is an error condition to configure overlapping root directories in different loaders.

2. Think the mere existence of a file is effectively like writing a `require` call for them, which is executed on demand (autoload) or upfront (eager load).

3. In that line, if two loaders manage files that translate to the same constant in the same namespace, the first one wins, the rest are ignored. Similar to what happens with `require` and `$LOAD_PATH`, only the first occurrence matters.

4. Projects that reopen a namespace defined by some dependency have to ensure said namespace is loaded before setup. That is, the project has to make sure it reopens, rather than define. This is often accomplished just loading the dependency.

5. Objects stored in reloadable constants should not be cached in places that are not reloaded. For example, non-reloadable classes should not subclass a reloadable class, or mixin a reloadable module. Otherwise, after reloading, those classes or module objects would become stale. Referring to constants in dynamic places like method calls or lambdas is fine.

6. In a given process, ideally, there should be at most one loader with reloading enabled. Technically, you can have more, but it may get tricky if one refers to constants managed by the other one. Do that only if you know what you are doing.

<a id="markdown-autoloading-explicit-namespaces-and-debuggers" name="autoloading-explicit-namespaces-and-debuggers"></a>
### Autoloading, explicit namespaces, and debuggers

As of this writing, Zeitwerk is unable to autoload classes or modules that belong to [explicit namespaces](#explicit-namespaces) inside debugger sessions. You'll get a `NameError`.

The root cause is that debuggers set trace points, and Zeitwerk does too to support explicit namespaces. A debugger session happens inside a trace point handler, and Ruby does not invoke other handlers from within a running handler. Therefore, the code that manages explicit namespaces in Zeitwerk does not get called by the interpreter. See [this issue](https://github.com/deivid-rodriguez/byebug/issues/564#issuecomment-499413606) for further details.

As a workaround, you can eager load. Zeitwerk tries hard to succeed or fail consistently both autoloading and eager loading, so switching to eager loading should not introduce any interference in your debugging logic, generally speaking.

<a id="markdown-pronunciation" name="pronunciation"></a>
## Pronunciation

"Zeitwerk" is pronounced [this way](http://share.hashref.com/zeitwerk/zeitwerk_pronunciation.mp3).

<a id="markdown-supported-opal-versions" name="supported-opal-versions"></a>
## Supported Opal versions

Opal Zeitwerk currently works with Opal releases >= 1.3.0. For the Gemfile:
```
gem 'opal', '>= 1.3.0'
```

<a id="markdown-motivation" name="motivation"></a>
## Motivation

Since `require` has global side-effects, and there is no static way to verify that you have issued the `require` calls for code that your file depends on, in practice it is very easy to forget some.
That introduces bugs that depend on the load order. Zeitwerk provides a way to forget about `require` in your own code, just name things following conventions and done.

The original goal of Opal Zeitwerk was to bring a better autoloading mechanism for Isomorfeus.

<a id="markdown-license" name="license"></a>
## License

Released under the MIT License, Copyright (c) 2019–<i>ω</i> Xavier Noria, Jan Biedermann.
