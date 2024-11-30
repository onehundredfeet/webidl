package;

import idl.Options;


class SampleCustomCode extends idl.CustomCode {
    public override function getHLInclude() {
		return "
        #ifdef _WIN32
#pragma warning(disable:4305)
#pragma warning(disable:4244)
#pragma warning(disable:4316)
#endif

#include \"sample_custom.h\"
        ";
	}

	public override function getJVMInclude() {
		return "#include \"sample_custom.h\"";
	}

	public override function getEmscriptenInclude() {
		return "#include \"sample_custom.h\"";
	}

	public override function getJSInclude() {
		return "#include \"sample_custom.h\"";
	}

	public override function getHXCPPInclude() {
		return "#include \"sample_custom.h\"";
	}

}
class Generator {
	// Put any necessary includes in this string and they will be added to the generated files
	
	public static function main() {
        trace('Building...');
        var sampleCode : idl.CustomCode = new SampleCustomCode();
        var options = {
            idlFile: "lib/sample/sample.idl",
            target: null,
            packageName: "sample",
            nativeLib: "sample",
            glueDir: null,
            autoGC: true,
            defaultConfig: "Release",
            architecture: ArchAll,
            customCode: sampleCode
        };

		new idl.Cmd(options).run();
	}
}
