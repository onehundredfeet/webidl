package idl;

import sys.FileSystem;
import sys.io.File;

using StringTools;
using Lambda;

private var _defines = new Map<String, String>();
private var _hxCppDir:String;
private var _relBuildDir:String;
private var _absBuildDir:String;
private var _launchDir:String;


private function resolveString( s : String ) : String {
    while (s.contains("${") && s.contains("}")) {
        var start = s.indexOf("${");
        var end = s.indexOf("}", start);
        var key = s.substring(start + 2, end);
        var replace = resolveDefine(key);
        if (replace == null) {
            replace = resolveDefine(key.toLowerCase());
        }
        s = s.substring(0, start) + replace + s.substring(end + 1);
    }
    return s;
}
private function resolveDefine( key : String ) : String {
    var value = _defines.get(key);
    if (value == null) {
        return null;
    }
    return resolveString(value);
}


private function cleanPath( path : String ) : String {
    path = path.replace("\\", "/");
    path = path.replace("//", "/");
    return path;
}

private function resolveSourcePath(file:Xml, files:Xml):String {
	var name = file.get('name');
	var dir = files.get('dir');

	if (name == null) {
		trace(file);
		trace(files);
		throw('File element must have a name attribute');
	}
	if (name == "${resourceFile}")
		return null;

	name = resolveString(name);
	if (name.startsWith('/') && FileSystem.exists(name))
		return cleanPath(name);

	if (dir == null) {
		if (FileSystem.exists(name))
			return name;
		// try build dir
		var buildPath = '${_absBuildDir}/${name}';
	}
	if (dir != null) {
		dir = resolveString(dir);
		var path = '${dir}/${name}';
		if (FileSystem.exists(path))
			return cleanPath(path);
	}

	var parentPath = files.get('path');
	if (parentPath != null) {
		var dir = parentPath.split('/').slice(0, -1).join('/');
		var path = '${dir}/${name}';
		path = path.replace("${HXCPP}", _hxCppDir);
		if (FileSystem.exists(path))
			return cleanPath(path);
	}

	throw('Cannot resolve source path for ${name} on ${file} within ${files}');

	return cleanPath(name);
}

class NodeCriteria {
	public function new(tags:Array<String>, condUnless:String, condIf:String) {
		this.tags = [];
		this.condIf = condIf;
		this.condUnless = condUnless;
	}

	public var tags:Array<String>;
	public var condUnless:String;
	public var condIf:String;

    public static function matchNode(e:Xml):Bool {
        var criteria = NodeCriteria.fromNode(e);
        if (criteria != null && !criteria.match()) {
            return false;
        }
        return true;
    }
	public static function fromNode(e:Xml):NodeCriteria {
		var tags = e.get('tags');
		var condUnless = e.get('unless');
		var condIf = e.get('if');

		if (tags == null && condUnless == null && condIf == null)
			return null;

		if (tags != null && tags.length == 0)
			tags = null;
		return new NodeCriteria(tags == null ? null : tags.split(',').map((x) -> x.trim()), condUnless, condIf);
	}

	public function match():Bool {
		if (condIf != null) {
			if (resolveDefine(condIf) == null)
				return false;
		}
		if (condUnless != null) {
			if (resolveDefine(condUnless) != null)
				return false;
		}
		return true;
	}

	@:keep
	public function toString() {
		var tagInfo = tags != null ? tags.join(',') : "";
		var unlessInfo = condUnless != null ? 'unless:${condUnless}' : '';
		var ifInfo = condIf != null ? 'if:${condIf}' : '';
		return '${tagInfo} ${unlessInfo} ${ifInfo}';
	}
}


private function collapseSections( n : Xml ) {
    var sectionsKeep = [];
    var sectionsRemove = [];

    for (e in n.elementsNamed('section')) {
        if (!NodeCriteria.matchNode(e)) {
            sectionsRemove.push(e);
            continue;
        }
        sectionsKeep.push(e);
        sectionsRemove.push(e);
    }

    for (e in sectionsKeep) {
        for (c in e.elements()) {
            n.addChild(c);
        }
    }

    for (e in sectionsRemove) {
        n.removeChild(e);
    }

}
class CompileBlock {
	function new(root:Xml, files:Array<Xml>) {
		this.id = root.get('id');
		this.root = root;
		this.files = files;
	}

	public var root:Xml;
	public var files:Array<Xml>;
	public var id:String;

	public static function fromXml(root:Xml):CompileBlock {
        collapseSections(root);
		var blockCriteria = NodeCriteria.fromNode(root);
		if (blockCriteria != null && !blockCriteria.match()) {
			return null;
		}
		var files = [for (f in root.elements()) f].filter((f) -> {
			if (f.nodeName != 'file')
				return false;
			var fileCriteria = NodeCriteria.fromNode(f);
			if (fileCriteria != null && !fileCriteria.match()) {
				return false;
			}
			return true;
		});

		// if (files.length == 0)
		// 	return null;

		for (f in files) {
			var srcPath = resolveSourcePath(f, root);
			if (srcPath == null) {
				throw('Cannot resolve source path for ${f} on ${root}');
			}
            if (!srcPath.startsWith('/')) {
                srcPath = FileSystem.absolutePath(srcPath);
            }
			f.set('srcPath', srcPath);
		}
		return new CompileBlock(root, files);
	}
}

class Target {
    function new(root:Xml) {
        this.root = root;
    }

    public var root:Xml;

    public function merge(otherRoot:Xml) {
        for (a in otherRoot.attributes()) {
            this.root.set(a, otherRoot.get(a));
        }
        for (e in otherRoot.elements()) {
            this.root.addChild(e);
        }
    }
    public static function fromXml(root:Xml):Target {
        collapseSections(root);

        return new Target(root);
    }
}

class GenerateCMakeHXCPP {
	static var _builder:StringBuf;

	static function addLine(line:String) {
		_builder.add(line);
		_builder.add('\n');
	}

	static function resolvePath(path:String) {
		if (FileSystem.exists(path))
			return path;
		//        trace('Resolving path: ${path}');
		path = path.replace("${HXCPP}", _hxCppDir);
		if (FileSystem.exists(path))
			return path;
		if (path.startsWith('/'))
			return path;
		// try prepending hxcpp dir
		path = '${_hxCppDir}/${path}';
		if (FileSystem.exists(path))
			return path;
		return path;
	}

	static function getFlatXML(path:String, included:Array<String>):Array<Xml> {
        var rpath = resolvePath(path);
		var xmlStr = File.getContent(rpath);
		var xmlRoot = Xml.parse(xmlStr).firstElement();
		var elements = [for (e in xmlRoot.elements()) e];

        if (included.contains(rpath)) {
//            trace('Already included: ${rpath}');
            return [];
        }
		included.push(rpath);

		var finalElements = [];

		for (e in elements) {
			if (e.nodeName == 'include') {
				var name = e.get('name');

				var actualPath = name;
				if (included.contains(actualPath)) {
//					trace('Already included: ${actualPath}');
					continue;
				}

//				trace('Recursing into include: ${name}');

				var includeElements = getFlatXML(actualPath, included);
				for (ie in includeElements) {
					finalElements.push(ie);
				}
				// var includePath = e.get('path');
				// var includeElements = getFlatXML(includePath);
				// finalElements = finalElements.concat(includeElements);
			} else {
				if (e.nodeName == 'files') {
					e.set('path', path);
				}
				finalElements.push(e);
			}
		}

		return finalElements;

		// var files = elements.filter(function(e) return e.nodeName == 'file');
		// var include = elements.filter(function(e) return e.nodeName == 'include');
		// var sets = elements.filter(function(e) return e.nodeName == 'set');

		// trace(elements.map(function(e) return e.nodeName));
	}

	public static function main() {
		var args = Sys.args();

		_launchDir = Sys.getCwd();
		var buildDir = args.shift();

		if (buildDir.startsWith('/')) {
			_absBuildDir = buildDir;
			_relBuildDir = buildDir.replace(_launchDir + "/", '');
		} else {
			_relBuildDir = buildDir;
			_absBuildDir = '${_launchDir}/${_relBuildDir}';
		}
		trace('Build dir: ${_absBuildDir} | ${_relBuildDir}');
		var includeDirs = new Array<String>();
		var libDirs = new Array<String>();

		while (args.length > 0) {
			var arg = args.shift();
			switch (arg) {
				case "--I":
					includeDirs.push(args.shift());
				case "--L":
					libDirs.push(args.shift());
				default:
			}
		}
		trace('Building CMakeLists.txt in ${_relBuildDir} from ${_launchDir}');

		for (i in includeDirs) {
			trace('Include dir: ${i}');
		}
		_builder = new StringBuf();

		var optionsStr = File.getContent('${_relBuildDir}/Options.txt');

		for (o in optionsStr.split('\n')) {
			o = o.trim();
			if (o.length == 0)
				continue;
			var parts = o.split('=');
			var key = parts[0].trim();
			var value = parts[1].trim();
			_defines.set(key, value);
		}

		for (o in _defines.keyValueIterator()) {
			trace('${o.key} = ${o.value}');
		}

		// var xmlStr = File.getContent('${outDir}/Build.xml');

		// var xmlRoot = Xml.parse(xmlStr).firstElement();
		// var elements = [for (e in xmlRoot.elements()) e];
		// var files = elements.filter(function(e) return e.nodeName == 'file');
		// var include = elements.filter(function(e) return e.nodeName == 'include');
		// var sets = elements.filter(function(e) return e.nodeName == 'set');

		if (resolveDefine('hxcpp') == null) {
			trace('hxcpp not set');
			return;
		}
		_hxCppDir = resolveDefine('hxcpp');
		if (_hxCppDir.endsWith('/')) {
			_hxCppDir = _hxCppDir.substring(0, _hxCppDir.length - 1);
		}
		trace('hxcpp dir: ${_hxCppDir}');

		//        var xml = getFlatXML('${hxCppDir}/toolchain/setup.xml');  // not very meaningful
		var includes = [];
		var haxeTargetXML = getFlatXML('${_hxCppDir}/toolchain/haxe-target.xml', includes);
		var buildXML = getFlatXML('${_relBuildDir}/Build.xml', includes);

		var allElements = haxeTargetXML.concat(buildXML);

        for (s in allElements.filter((e) -> e.nodeName == "set")) {
            if (NodeCriteria.matchNode(s)){
                var name = s.get('name');
                var value = s.get('value');
                    trace('Setting ${name} = ${value}');
                _defines.set(name, value);    
            }
        }
		var hxcppFileBlocks = new Map<String, CompileBlock>();
		for (e in allElements.filter((e) -> e.nodeName == "files")) {
			var filesCriteria = NodeCriteria.fromNode(e);
			var id = e.get('id');
			var block = CompileBlock.fromXml(e);
			if (block == null) {
//				trace('Skipping block ${id}');
				continue;
			}
            hxcppFileBlocks.set(id, block);

//			trace('Found file block: ${id}');
			// for (f in block.files) {
			// 	var srcPath = f.get('srcPath');
			// 	trace('\t${srcPath}');
			// }
		}

        var targetMap = new Map<String, Target>();

        for (e in allElements.filter((e) -> e.nodeName == "target")) {
            var id = e.get('id');
            if (id == null) {
                trace('Target missing id');
                continue;
            }
            if (targetMap.exists(id)) {
                targetMap.get(id).merge(e);
            } else {
                targetMap.set(id, Target.fromXml(e));
            }            
        }

        var haxeTarget = targetMap.get('haxe');

        if (haxeTarget == null) {
            trace('No haxe target');
            return;
        }
		
        var targetBlocks = [];

        var cppIncludeDirs = [];
        var cppLibDirs = [];
        var miscCompilerFlags = [];
        var cppWarnings = [];
        var cppDefines = [];

        for (e in haxeTarget.root.elements()) {
            if (!NodeCriteria.matchNode(e)) {
                continue;
            }
            switch (e.nodeName) {
                case 'files':
                var block = hxcppFileBlocks.get(e.get('id'));
                if (block == null) {
                    trace('No block for ${e.get('id')}');
                    continue;
                }
                for (cf in block.root.elementsNamed('compilerflag')) {
                    var value = resolveString(cf.get("value"));
                    if (value.startsWith('-I')) {
                        value = value.substring(2);
                        if (!cppIncludeDirs.contains(value)) cppIncludeDirs.push(cleanPath(value));
                    } else if (value.startsWith('-L')) {
                        cppLibDirs.push(value.substring(2));
                    } else if (value.startsWith('-W')) {
                        cppWarnings.push(value.substring(2));
                    } else if (value.startsWith('-D')) {
                        value = value.substring(2);
                        if (!cppDefines.contains(value)) cppDefines.push(value);
                    } else {
                        miscCompilerFlags.push(value);
                    }
//                      trace('Compiler flag: ${value}');
                }
                if (block.files.length == 0) {
                    continue;
                }
                trace('Adding files from ${e.get('id')}');
                for (f in block.files) {
                    trace('\t${f.get('srcPath')}');
                }
                case 'options':
                default:
                trace('Unknown node: ${e.nodeName}');
            }
        }

        trace('Include dirs: ${cppIncludeDirs.join(',')}');
        trace('Lib dirs: ${cppLibDirs.join(',')}');
        trace('Misc compiler flags: ${miscCompilerFlags.join(',')}');
        trace('Compiler warnings: ${cppWarnings.join(',')}');
        trace('Compiler defines: ${cppDefines.join(',')}');



		File.saveContent('${_relBuildDir}/CMakeLists.txt', _builder.toString());
	}
}


// - Parsing include: /Users/rcleven/git/hxcpp/toolchain/setup.xml
		// - Parsing include: /Users/rcleven/.hxcpp_config.xml (section "vars")
		// - Running process: xcode-select --print-path
		// - Parsing include: /Users/rcleven/git/hxcpp/toolchain/finish-setup.xml
		// - Parsing makefile: /Users/rcleven/git/hl-idl/example/bin/cpp/Build.xml
		// - Parsing include: /Users/rcleven/git/hxcpp/build-tool/BuildCommon.xml
		// - Parsing include: /Users/rcleven/git/hxcpp/toolchain/haxe-target.xml
		// - Parsing include: /Users/rcleven/git/hxcpp/src/hx/libs/zlib/Build.xml
		// - Parsing include: /Users/rcleven/git/hl-idl/example/sample.xml
		// - Parsing include: /Users/rcleven/git/hl-idl/example/sample.xml
		// - Parsing include: /Users/rcleven/git/hxcpp/toolchain/mac-toolchain.xml
		// - Parsing include: /Users/rcleven/git/hxcpp/toolchain/gcc-toolchain.xml
		// - Adding path: /Applications/Xcode.app/Contents/Developer/usr/bin
		// - Parsing compiler: /Users/rcleven/git/hxcpp/toolchain/common-defines.xml
		// - Parsing include: /Users/rcleven/.hxcpp_config.xml (section "exes")

		// - Parsing include: ${hxCppDir}/toolchain/setup.xml
		// - Parsing include: /Users/rcleven/.hxcpp_config.xml (section "vars")
		// - Running process: xcode-select --print-path
		// - Parsing include: ${hxCppDir}/toolchain/finish-setup.xml
		// - Parsing makefile: /Users/rcleven/git/hl-idl/example/bin/cpp/Build.xml
		// - Parsing include: ${hxCppDir}/build-tool/BuildCommon.xml
		// - Parsing include: ${hxCppDir}/toolchain/haxe-target.xml
		// - Parsing include: /Users/rcleven/git/hl-idl/example/sample.xml
		// - Parsing include: /Users/rcleven/git/hl-idl/example/sample.xml
		// - Parsing include: ${hxCppDir}/toolchain/mac-toolchain.xml
		// - Parsing include: ${hxCppDir}/toolchain/gcc-toolchain.xml
		// - Adding path: /Applications/Xcode.app/Contents/Developer/usr/bin
		// - Parsing compiler: ${hxCppDir}/toolchain/common-defines.xml
		// - Parsing include: /Users/rcleven/.hxcpp_config.xml (section "exes")

		// trace(elements);

//         <target id="haxe" tool="linker" toolid="${haxelink}" output="${HAXE_OUTPUT_FILE}">
//   <files id="haxe"/>
//   <options name="Options.txt"/>
//   <ext value="${LIBEXTRA}.a" if="iphoneos" unless="dll_import" />
//   <ext value="${LIBEXTRA}.a" if="iphonesim" unless="dll_import" />
//   <ext value="${LIBEXTRA}.a" if="appletvos" unless="dll_import" />
//   <ext value="${LIBEXTRA}.a" if="appletvsim" unless="dll_import" />
//   <ext value="${LIBEXTRA}.a" if="watchos" unless="dll_import" />
//   <ext value="${LIBEXTRA}.a" if="watchsimulator" unless="dll_import" />

//   <section if="android">
//      <ext value="${LIBEXTRA}.so" />
//      <ext value="${LIBEXTRA}.a"  if="static_link" />
//      <ext value="${LIBEXTRA}" if="exe_link" />
//   </section>

//   <fullouput name="${HAXE_FULL_OUTPUT_NAME}" if="HAXE_FULL_OUTPUT_NAME" />
//   <fullunstripped name="${HAXE_FULL_UNSTRIPPED_NAME}" if="HAXE_FULL_UNSTRIPPED_NAME" />

//   <files id="__main__" unless="static_link" />
//   <files id="__lib__" if="static_link"/>
//   <files id="__resources__" />
//   <files id="__externs__" />
//   <files id="runtime" unless="dll_import" />
//   <files id="cppia" if="scriptable" />
//   <files id="tracy" if="HXCPP_TRACY" />
//   <files id="rc" unless="static_link" />
//   <lib name="-lpthread" if="linux" unless="static_link" />
//   <lib name="-ldl" if="linux" unless="static_link" />
// </target>



// /lib/idl/GenerateCMakeHXCPP.hx:345: Setting hxcpp_api_level = ${HXCPP_API_LEVEL}
// ../lib/idl/GenerateCMakeHXCPP.hx:345: Setting CPPIA_JIT = 1
// ../lib/idl/GenerateCMakeHXCPP.hx:345: Setting EXESUFFIX = .exe
// ../lib/idl/GenerateCMakeHXCPP.hx:345: Setting HAXE_OUTPUT_PART = ${HAXE_OUTPUT}
// ../lib/idl/GenerateCMakeHXCPP.hx:345: Setting HAXE_OUTPUT_FILE = ${LIBPREFIX}${HAXE_OUTPUT_PART}${DBG}
// ../lib/idl/GenerateCMakeHXCPP.hx:345: Setting magiclibs = 1
// ../lib/idl/GenerateCMakeHXCPP.hx:345: Setting HXCPP_API_LEVEL = 430
// ../lib/idl/GenerateCMakeHXCPP.hx:345: Setting HAXE_OUTPUT = SampleMain
// ../lib/idl/GenerateCMakeHXCPP.hx:345: Setting ZLIB_DIR = ${HXCPP}/project/thirdparty/zlib-1.2.13