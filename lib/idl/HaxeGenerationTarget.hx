package idl;
import idl.Data;
import haxe.macro.Expr;

using StringTools;
using idl.macros.MacroTools;

abstract class HaxeGenerationTarget {
    var opts: Options;
    var typeNames : Map<String, haxe.macro.TypePath>;
    public function new(opts: Options, typeNames : Map<String, haxe.macro.TypePath>) {
        this.opts = opts;
        this.typeNames = typeNames;
    }
    public abstract function makeNative( name : String, p : Position ) : MetadataEntry;
    public abstract function makeType( t : TypeAttr, isReturn:Bool ) : ComplexType;
    public abstract function makeVectorType( t : TypeAttr, vt : Type, vdim : Int, isReturn:Bool ): ComplexType;
    public abstract function getTargetCondition() : String;
    
    private static function capitalize(text:String) {
		return text.charAt(0).toUpperCase() + text.substring(1);
	}

    function makeName(name:String) {
		// name - list of comma separated prefixes
		if (opts.chopPrefix != null) {
			var prefixes = opts.chopPrefix.split(',');
			for (prefix in prefixes) {
				if (StringTools.startsWith(name, prefix)) {
					name = name.substr(prefix.length);
				}
			}
		}
		return capitalize(name);
	}
}
