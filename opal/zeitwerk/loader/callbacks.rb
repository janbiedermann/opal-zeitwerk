module Zeitwerk::Loader::Callbacks
  include Zeitwerk::RealModName

  # Invoked from our decorated Kernel#require when a managed file is autoloaded.
  #
  # @private
  # @param file [String]
  # @return [void]
  def on_file_autoloaded(file)
    cref = autoloads.delete(file)
    to_unload[cpath(*cref)] = [file, cref] if reloading_enabled?
    Zeitwerk::Registry.unregister_autoload(file)

    # "constant #{cpath(*cref)} loaded from file #{file}" if cdef?(*cref)
    if !cdef?(*cref)
      raise Zeitwerk::NameError.new("expected file #{file} to define constant #{cpath(*cref)}, but didn't", cref.last)
    end
  end

  # Invoked from our decorated Kernel#require when a managed directory is
  # autoloaded.
  #
  # @private
  # @param dir [String]
  # @return [void]
  def on_dir_autoloaded(dir)
    if cref = autoloads.delete(dir)
      autovivified_module = cref[0].const_set(cref[1], Module.new)

      # "module #{autovivified_module.name} autovivified from directory #{dir}"

      to_unload[autovivified_module.name] = [dir, cref] if reloading_enabled?

      # We don't unregister `dir` in the registry because concurrent threads
      # wouldn't find a loader associated to it in Kernel#require and would
      # try to require the directory. Instead, we are going to keep track of
      # these to be able to unregister later if eager loading.
      autoloaded_dirs << dir

      on_namespace_loaded(autovivified_module)
    end
  end

  # Invoked when a class or module is created or reopened, either from the
  # tracer or from module autovivification. If the namespace has matching
  # subdirectories, we descend into them now.
  #
  # @private
  # @param namespace [Module]
  # @return [void]
  def on_namespace_loaded(namespace)
    if subdirs = lazy_subdirs.delete(real_mod_name(namespace))
      subdirs.each do |subdir|
        set_autoloads_in_dir(subdir, namespace)
      end
    end
  end
end
