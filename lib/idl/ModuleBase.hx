package idl;

#if macro

import haxe.macro.Context;

abstract class ModuleBase {
    var opts : Options;
    var pack : Array<String>;

    function new( pack, opts:Options) {
        this.opts = opts;
        this.pack = pack;
    }

    function makeName( name : String ) {
		// name - list of comma separated prefixes
		if( opts.chopPrefix != null ) {
			var prefixes = opts.chopPrefix.split(',');
			for (prefix in prefixes) {
				if (StringTools.startsWith(name, prefix)) {
					name = name.substr(prefix.length);
				}
			}
		}
		return capitalize(name);
	}

    
	function loadIDL() {
		// load IDL
		var file = opts.idlFile;
		var content = try {
			file = Context.resolvePath(file);
			sys.io.File.getBytes(file);
		} catch (e:Dynamic) {
			Context.error("" + e, Context.currentPos());
			return null;
		}

        return content;
	}

    /**
	 * Capitalize the first letter of a string
	 * @param text The string to capitalize
	 */
	private static function capitalize(text:String) {
		return text.charAt(0).toUpperCase() + text.substring(1);
	}

}
#end
