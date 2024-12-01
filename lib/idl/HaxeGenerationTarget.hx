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
    public abstract function makeNative( iname : String, midfix : String, fname : String, argc : Null<Int>, p : Position ) : Array<MetadataEntry>;
    public abstract function makeType( t : TypeAttr, isReturn:Bool ) : ComplexType;
    public abstract function makeVectorType( t : TypeAttr, vt : Type, vdim : Int, isReturn:Bool ): ComplexType;
    public abstract function getTargetCondition() : String;
    public abstract function getInterfaceTypeDefinitions(iname : String, pack : Array<String>, dfields : Array<Field>, p : Position) : Array<TypeDefinition>;

	public function externalFunction(args:Array<FunctionArg>, ret : ComplexType = null, expr :Expr = null) : FieldType {
		return FFun({
			ret: ret,
			expr: needsStubs() ? expr : null,
			args: args,
		});
	
	}

	public function embeddedFunction(args:Array<FunctionArg>, ret : ComplexType = null, expr :Expr = null) : FieldType {
		return FFun({
			ret: ret,
			expr: expr,
			args: args,
		});
	
	}

    public function needsStubs() : Bool {
        return true;
    }
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
