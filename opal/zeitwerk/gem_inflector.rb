module Zeitwerk
  class GemInflector < Inflector
    # @sig (String) -> void
    def initialize(root_file)
      namespace     = File.basename(root_file, ".rb")
      lib_dir       = File.dirname(root_file)
      @version_file = File.join(lib_dir, namespace, "version")
    end

    # @sig (String, String) -> String
    def camelize(basename, abspath)
      abspath == @version_file ? "VERSION" : super
    end
  end
end
