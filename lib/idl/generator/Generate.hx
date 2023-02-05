package idl.generator;
import idl.Options;

class Generate {
    static function initOpts(opts:Options) {
		if (opts.outputDir == null)
			opts.outputDir = "";
		else if (!StringTools.endsWith(opts.outputDir, "/"))
			opts.outputDir += "/";
	}

    public static function generateCpp(opts:Options) {
        initOpts(opts);
        switch (opts.target) {
            case TargetHL:GenerateHL.generateCpp(opts);
            case TargetJVM:GenerateJVM.generateCpp(opts);
//            case TargetJS:GenerateJS.generateJS(opts, []);
            default:
                throw "Unsupported target: " + opts.target;
        }
    }
}