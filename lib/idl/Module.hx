package idl;
#if macro
class  Module{
    public static function build( opts : Options ) {
        return switch(opts.target) {
            case TargetHL: ModuleHL.build(opts);
            case TargetJVM: ModuleJVM.build(opts);
            case TargetHXCPP: ModuleCPP.build(opts);
            case TargetEmscripten: ModuleCPP.build(opts);
            default: throw 'Unrecognized target ${opts.target}';
        }
    }
}
#end