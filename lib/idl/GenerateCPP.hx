package idl;

import sys.FileSystem;
import idl.Options.CPPFlavour;
import idl.GenerateBase;
import haxe.macro.Expr.Function;
import idl.Data;
import idl.Options;

class GenerateCPP extends GenerateBase {
    public function new(opts:Options) {
        super(opts);
    }
    public function generateGlue() : Void {
        var output = new StringBuf();

         
        output.add('#pragma once\n');
        for (h in opts.includes) {
            output.add('#include "' + h + '"\n');
        }
        output.add('\n');
        output.add(opts.customCode.getHXCPPInclude());
//        var cammelCase = opts.packageName.charAt(0).toUpperCase() + opts.packageName.substr(1);

        var path = FileSystem.absolutePath( opts.glueDir + '/${opts.nativeLib}_hxcpp_idl.h');

		sys.io.File.saveContent(path,output.toString());

	}
    public function generateHX() : Void {
		var haxehl = new HaxeGenerate(opts);
		haxehl.generate();
	}
	
}
