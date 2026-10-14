# Parser must retain syntax comments while treating this file as inert source.
require "missing_source_dependency"

module NativeDependency
  ffi_func :native_call, [:int], :int
end
