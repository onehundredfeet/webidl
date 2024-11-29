package idl;
#if macro
class  Module{
    public static function build( opts : Options ) {
        return switch(opts.target) {
            case TargetHL: ModuleHL.build(opts);
            case TargetJVM: ModuleJVM.build(opts);
            case TargetCPP: ModuleCPP.build(opts, CPP_HXCPP);
            case TargetEmscripten: ModuleCPP.build(opts, CPP_Emscripten);
            default: throw 'Unrecognized target ${opts.target}';
        }
    }
}
#end