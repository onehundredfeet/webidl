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

	public static function generateCpp(target = idl.generator.Options.Target.TargetHL) {
		options.target = target;
		options.includeCode = switch (target) {
			case idl.generator.Options.Target.TargetHL: HL_INCLUDE;
			case idl.generator.Options.Target.TargetJVM: JVM_INCLUDE;
			default: "";
		};
		idl.generator.Generate.generateCpp(options);
	}
}
#end
