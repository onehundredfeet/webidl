package idl;
import idl.Options;

class Cmd {
	// Put any necessary includes in this string and they will be added to the generated files

	var _options : Options;
    var target = "hl";
	var builder = "Ninja";
    var idlPath = "ext/hl-idl";
    var config = null;
	var arch = null;
	public function new(options : Options) {
		_options = options;
		arch = options.architecture != null ? options.architecture : "x86_64";
		config = options.defaultConfig != null ? options.defaultConfig : "Debug";
	}


	function updateOptions() {
		_options.target =  switch (target) {
			case "hashlink", "hl": idl.Options.Target.TargetHL;
			case "java", "jvm": idl.Options.Target.TargetJVM;
			case "js": idl.Options.Target.TargetJS;
			case "cpp", "hxcpp": idl.Options.Target.TargetHXCPP;
			case "em", "emscripten": idl.Options.Target.TargetEmscripten;
			default: idl.Options.Target.TargetHL;
		};
        


		if (_options.installDir == null) _options.installDir = 'installed/${target}/${arch}/${config}';
		if (_options.buildDir == null) _options.buildDir = 'build/${target}/${arch}/${config}';

        if (_options.glueDir == null) _options.glueDir = 'src/${target}';
        if (_options.hxDir == null) _options.hxDir = 'lib';
	}


	
	function configure() {
		sys.FileSystem.createDirectory(_options.buildDir);
		sys.FileSystem.createDirectory(_options.installDir);
		var architectureSwitch = switch(_options.architecture) {
			case ArchX86_64: "-DTARGET_ARCH=\"x86_64\"";
			case ArchArm64: "-DTARGET_ARCH=\"arm64\"";
			case ArchAll: "-DCMAKE_OSX_ARCHITECTURES=\"x86_64;arm64\""; 
			default: "";
		};

        var cmd = 'cmake -G"${builder}" ${architectureSwitch} -DH_GLUE_ROOT=${_options.glueDir} -DPATH_TO_IDL=${idlPath} -DTARGET_HOST=${target} -DCMAKE_BUILD_TYPE=${config} -DCMAKE_INSTALL_PREFIX=${_options.installDir} -B ${_options.buildDir}';
        trace('$cmd');
        Sys.command(cmd);
	}

	function build() {
        var cmd = 'cmake --build ${_options.buildDir}';
        trace('$cmd');
        Sys.command(cmd);
	}

	function install() {

		var cmd = 'cmake --install ${_options.buildDir}';
		trace('$cmd');
		Sys.command(cmd);
	}

	public function run() {		
		var args = Sys.args();

		if (args.length > 0) {
			var cmd = args.shift();

            while (args.length > 0) {
                var arg = args.shift();
                switch (arg) {
                    case "--target":
                        target = args.shift();
                    case "--builder":
                        builder = args.shift();
                    case "--arch":
                        arch = args.shift();
                    case "--idl":
                        idlPath = args.shift();
                    case "--config":
                        config = args.shift();
                    case "--hx":
                        _options.generateSource = true;
					case "--installdir":
						_options.installDir = args.shift();
					case "--builddir":
						_options.buildDir = args.shift();
					case "--gluedir":
						_options.glueDir = args.shift();
					case "--hxdir":
						_options.hxDir = args.shift();
                    default:
						trace('Unknown argument ${arg}');
                }
            }


			updateOptions();

			switch (cmd) {
				case "generate":
					trace('Generating code');
					idl.GenerateBase.generate(_options);
				case "configure":
					configure();
				case "build":
					configure();
					build();
				case "install":
					install();
				default: trace('Unknown command ${cmd}');
			}
		} else {
            trace("Usage: haxe config.hxml [generate|build|install] [options]");
			trace("  generate: Generate the target code");
			trace("  build: Build the target code");
			trace("  install: Install the target code");
			trace("  --target: The target platform (hl, jvm)");
			trace("  --builder: The build system (Ninja, Make)");
			trace("  --arch: The target architecture (x86_64, arm64, all)");
			trace("  --idl: The path to the idl directory");
			trace("  --config: The build configuration (Debug, Release)");
        }
	}
}
