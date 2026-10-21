# Parser must retain syntax comments while treating this file as inert source.
require_relative "side_effect"

module NativeDependency
  ffi_func :native_call, [:int], :int
  @@count = 0
  File.write("/tmp/fleek-spinel-source-executed", "yes")
end
