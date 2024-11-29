package;

#if eval
class Generator {
	// Put any necessary includes in this string and they will be added to the generated files
	static var HL_INCLUDE = "
#ifdef _WIN32
#pragma warning(disable:4305)
#pragma warning(disable:4244)
#pragma warning(disable:4316)
#endif

#include \"sample_custom.h\"
";

	static var JVM_INCLUDE = "
	#include \"sample_custom.h\"
";
	static var options = {
		idlFile: "lib/sample.idl",
		target: null,
		packageName: "sample",
		nativeLib: "sample",
		outputDir: "src",
		includeCode: null,
		autoGC: true
	};

	static var HXCPP_INCLUDE = "
#ifdef _WIN32
#pragma warning(disable:4305)
#pragma warning(disable:4244)
#pragma warning(disable:4316)
#endif

#include \"sample_custom.h\"
";
	static var EMSCRIPTEN_INCLUDE = "
	#include \"sample_custom.h\"
";

	public static function generate(target = idl.Options.Target.TargetHL, makeSrc = false) {
		options.target = target;
		options.generateSource = makeSrc;
		options.includeCode = switch (target) {
			case idl.Options.Target.TargetHL: HL_INCLUDE;
			case idl.Options.Target.TargetJVM: JVM_INCLUDE;
			case idl.Options.Target.TargetCPP: HXCPP_INCLUDE;
			case idl.Options.Target.TargetEmscripten: EMSCRIPTEN_INCLUDE;
			case idl.Options.Target.TargetJS: EMSCRIPTEN_INCLUDE;
			
			default: throw 'Unrecognized target ${target}';
		};
		idl.generator.Generate.generate(options);
	}
}
#end
