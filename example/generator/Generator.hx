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

        ";
	}

	public override function getJVMInclude() {
		return "";
	}

	public override function getEmscriptenInclude() {
		return "";
	}

	public override function getJSInclude() {
		return "";
	}

	public override function getHXCPPInclude() {
		return "";
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
            architecture: ArchX86_64,
            customCode: sampleCode,
			includes: ["sample_custom.h"]
        };

		new idl.Cmd(options).run();
	}
}
