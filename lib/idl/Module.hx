package idl;

#if hl
typedef Module=idl.ModuleHL;
#elseif (java || jvm)
typedef Module=idl.ModuleJVM;
#end
