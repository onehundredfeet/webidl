package idl;

#if hl
class  Module extends idl.ModuleHL {}
#elseif (java || jvm)
class  Module extends idl.ModuleJVM {}
#elseif eval

#else
#error "Unsupported target host"
#end
