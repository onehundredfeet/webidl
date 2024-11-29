package idl.generator;
import idl.Options;

class Generate {
    static function initOpts(opts:Options) {
		if (opts.outputDir == null)
			opts.outputDir = "";
		else if (!StringTools.endsWith(opts.outputDir, "/"))
			opts.outputDir += "/";

        switch (opts.target) {
            case TargetHL:
            case TargetJVM:
            case TargetHXCPP:opts.cppFlavour = CPP_HXCPP;
            case TargetEmscripten:opts.cppFlavour = CPP_EMSCRIPTEN;
            default:
                throw "Unsupported target: " + opts.target;
        }

        return switch(opts.target) {
            case TargetHL:new GenerateHL(opts);
            case TargetJVM:new GenerateHL(opts);
            case TargetHXCPP:new GenerateHL(opts);
            case TargetEmscripten:new GenerateHL(opts);
            default:
                throw "Unsupported target: " + opts.target;
        }
	}

    public static function generate(opts:Options) {
        var generator = initOpts(opts);
        generator.generateGlue();
        if (opts.generateSource) {
             generator.generateHX();
        }
    }
}