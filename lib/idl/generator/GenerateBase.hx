package idl.generator;
import idl.Options;

abstract class GenerateBase {

    var opts:Options;
    public function new (opts:Options) {
        this.opts = opts;
    }

    abstract public function generateGlue() : Void;
    abstract public function generateHX() : Void;

    function loadIDL(opts:Options) {
        var file = opts.idlFile;
		var content = sys.io.File.getBytes(file);
		var parse = new idl.generator.Parser();
		var decls = null;
		var gc = opts.autoGC;
		try {
			decls = parse.parseFile(file, new haxe.io.BytesInput(content));
		} catch (msg:String) {
			throw msg + "(" + file + " line " + parse.line + ")";
		}
        return decls;
    }

    function command(cmd, args:Array<String>) {
		Sys.println("> " + cmd + " " + args.join(" "));
		var ret = Sys.command(cmd, args);
		if (ret != 0)
			throw "Command '" + cmd + "' has exit with error code " + ret;
	}
}