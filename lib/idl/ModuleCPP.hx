package idl;
import idl.Options;
import idl.ModuleBase;

#if macro
class ModuleCPP extends ModuleBase{
    function new( pack, opts : Options) {
        super(pack, opts);       
    }
    public static function build( opts : Options ) {
        return null;
    }
}
#end