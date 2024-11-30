package idl;

class GenerateJS extends GenerateBase{

	public function new(opts:Options) {
		super (opts);
	}

	public function generateGlue() : Void {

	}
    public function generateHX() : Void {

	}



    public function generateJs(opts:Options, sources:Array<String>, ?params:Array<String>) {
		if (params == null)
			params = [];

		var hasOpt = false;
		for (p in params)
			if (p.substr(0, 2) == "-O")
				hasOpt = true;
		if (!hasOpt)
			params.push("-O2");

		var lib = opts.nativeLib;

		var emSdk = Sys.getEnv("EMSCRIPTEN");
		if (emSdk == null)
			throw "Missing EMSCRIPTEN environment variable. Install emscripten";
		var emcc = emSdk + "/emcc";

		// build sources BC files
		var outFiles = [];
		sources.push(lib + ".cpp");
		for (cfile in sources) {
			var out = opts.glueDir + cfile.substr(0, -4) + ".bc";
			var args = params.concat(["-c", cfile, "-o", out]);
			command(emcc, args);
			outFiles.push(out);
		}

		// link : because too many files, generate Makefile
		var tmp = opts.glueDir + "Makefile.tmp";
		var args = params.concat([
			"-s",
			'EXPORT_NAME="\'$lib\'"',
			"-s",
			"MODULARIZE=1",
			"--memory-init-file",
			"0",
			"-o",
			'$lib.js'
		]);
		var output = "SOURCES = " + outFiles.join(" ") + "\n";
		output += "all:\n";
		output += "\t" + emcc + " $(SOURCES) " + args.join(" ");
		sys.io.File.saveContent(tmp, output);
		command("make", ["-f", tmp]);
		sys.FileSystem.deleteFile(tmp);
	}
}