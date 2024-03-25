package idl;
import idl.Options;

class BuildBase {
	// Put any necessary includes in this string and they will be added to the generated files

	var _options : Options;

	public function new(options : Options) {
		_options = options;
		arch = options.architecture != null ? options.architecture : "x86_64";
		config = options.defaultConfig != null ? options.defaultConfig : "Debug";
	}

	function getHLInclude() {
		return "";
	}
	function getJVMInclude() {
		return "";
	}

	function generate() {
		_options.target =  switch (target) {
			case "hl": idl.Options.Target.TargetHL;
			case "jvm": idl.Options.Target.TargetJVM;
			default: idl.Options.Target.TargetHL;
		};
		_options.includeCode = switch (target) {
			case idl.Options.Target.TargetHL: getHLInclude();
			case idl.Options.Target.TargetJVM: getJVMInclude();
			default: "";
		};

		

		trace('Generating target ${target}');
		idl.generator.Generate.generateCpp(_options);
	}

	var target = "hl";
	var builder = "Ninja";
    var idlPath = "ext/hl-idl";
    var config = null;
	var arch = null;
	var installDir = null;

	function configure() {
		sys.FileSystem.createDirectory('build/${target}/${arch}/${config}');
		sys.FileSystem.createDirectory(installDir);
		var architectureSwitch = switch(_options.architecture) {
			case ArchX86_64: "-DTARGET_ARCH=\"x86_64\"";
			case ArchArm64: "-DTARGET_ARCH=\"arm64\"";
			case ArchAll: "-DCMAKE_OSX_ARCHITECTURES=\"x86_64;arm64\""; 
			default: "";
		};

        var cmd = 'cmake -G"${builder}" ${architectureSwitch} -DPATH_TO_IDL=${idlPath} -DTARGET_HOST=${target} -DCMAKE_BUILD_TYPE=${config} -DCMAKE_INSTALL_PREFIX=${installDir} -B build/${target}/${arch}/${config}';
        trace('$cmd');
        Sys.command(cmd);
	}

	function build() {
        var cmd = 'cmake --build build/${target}/${arch}/${config}';
        trace('$cmd');
        Sys.command(cmd);
	}

	function install() {

		var cmd = 'cmake --install build/${target}/${arch}/${config}';
		trace('$cmd');
		Sys.command(cmd);
	}

	function parseArgs() {		
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
					case "--dir":
						installDir = args.shift();
                    default:
                }
            }
			if (installDir == null) {
				installDir = 'installed/${target}/${arch}/${config}';
			}
			switch (cmd) {
				case "generate":
					generate();
				case "configure":
					configure();
				case "build":
					configure();
					build();
				case "install":
					install();
				default:
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
