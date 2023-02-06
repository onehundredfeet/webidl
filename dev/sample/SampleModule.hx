#if !macro
private typedef Import = haxe.macro.MacroType<[SampleModule.build()]>; 
#else

class SampleModule {

	static var config : idl.Options = {
		idlFile : "point.idl",
		nativeLib : "libpoint",
		includeCode : "#include \"point.h\"",
		autoGC : false,
	};
	
	public static function build() {
		return idl.Module.build(config);
	}

	public static function buildLibCpp() {
		idl.Generate.generateCpp(config);
	}
	
	public static function buildLibJS() {
		var sourceFiles = ["point.cpp"];
		idl.Generate.generateJs(config, sourceFiles);
	}
	
}

#end