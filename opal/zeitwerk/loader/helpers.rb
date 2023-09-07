# backtick_javascript: true

module Zeitwerk::Loader::Helpers
  private

  # --- Files and directories ---------------------------------------------------------------------

  # @sig (String) { (String, String) -> void } -> void
  def ls(dir)
    outer_ls = false
    # cache the Opal.modules keys array for subsequent ls calls during setup
    %x{
      if (#@module_paths === nil) {
        #@module_paths = Object.keys(Opal.modules);
        outer_ls = true;
      }
    }
    visited_abspaths = `{}`
    dir_first_char = dir[0]
    path_start = dir.size + 1
    path_parts = `[]`
    basename = ''
    @module_paths.each do |abspath|
      %x{
        if (abspath[0] === dir_first_char) {
          if (!abspath.startsWith(dir)) { #{next} }
          path_parts = abspath.slice(path_start).split('/');
          basename = path_parts[0];
          abspath = dir + '/' + basename;
          if (visited_abspaths.hasOwnProperty(abspath)) { #{next} }
          visited_abspaths[abspath] = true;
          #{yield basename, abspath unless ignored_paths.member?(abspath)}
        }
      }
    end
    # remove cache, because Opal.modules may change after setup
    %x{
      if (outer_ls) { #@module_paths = nil }
    }
  end

  # @sig (String) -> bool
  def ruby?(abspath)
    `Opal.modules.hasOwnProperty(abspath)`
  end

  # @sig (String) -> bool
  def dir?(path)
    dir_path = path + '/'
    module_paths = if @module_paths # possibly set by ls
                     @module_paths
                   else
                     `Object.keys(Opal.modules)`
                   end
    path_first = `path[0]`
    module_paths.each do |m_path|
      %x{
        if (m_path[0] !== path_first) { #{ next } }
        if (m_path.startsWith(dir_path)) { #{return true} }
      }
    end
    false
  end

  # --- Constants ---------------------------------------------------------------------------------

  # The autoload? predicate takes into account the ancestor chain of the
  # receiver, like const_defined? and other methods in the constants API do.
  #
  # For example, given
  #
  #   class A
  #     autoload :X, "x.rb"
  #   end
  #
  #   class B < A
  #   end
  #
  # B.autoload?(:X) returns "x.rb".
  #
  # We need a way to strictly check in parent ignoring ancestors.
  #
  # @sig (Module, Symbol) -> String?
  if method(:autoload?).arity == 1
    def strict_autoload_path(parent, cname)
      parent.autoload?(cname) if cdef?(parent, cname)
    end
  else
    def strict_autoload_path(parent, cname)
      parent.autoload?(cname, false)
    end
  end

  # @sig (Module, Symbol) -> String
  if Symbol.method_defined?(:name)
    # Symbol#name was introduced in Ruby 3.0. It returns always the same
    # frozen object, so we may save a few string allocations.
    def cpath(parent, cname)
      Object == parent ? cname.name : "#{real_mod_name(parent)}::#{cname.name}"
    end
  else
    def cpath(parent, cname)
      Object == parent ? cname.to_s : "#{real_mod_name(parent)}::#{cname}"
    end
  end

  # @sig (Module, Symbol) -> bool
  def cdef?(parent, cname)
    parent.const_defined?(cname, false)
  end

  # @raise [NameError]
  # @sig (Module, Symbol) -> Object
  def cget(parent, cname)
    parent.const_get(cname, false)
  end
end
