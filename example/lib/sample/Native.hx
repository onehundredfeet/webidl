package sample;


typedef Native = haxe.macro.MacroType<[
	idl.Module.build({
		idlFile: "sample/sample.idl",
		target: #if hl "hl" #elseif (java || jvm) "jvm" #else "Unsupported target host" #end,
		packageName: "sample",
		autoGC: true,
		nativeLib: "sample"
	})
]>;

