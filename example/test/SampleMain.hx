// This file is written entirely in the Haxe language
package ;

import haxe.zip.Uncompress;
import haxe.zip.Compress;

import sample.Sample;
import cpp.Reference;
import cpp.Pointer;


class SampleMain {
    static function main() {
        trace("Forcing bootstrap");
        var p = Compress.run(haxe.io.Bytes.ofString("Hello World"), 1);
        trace(Uncompress.run(p));
        //trace('DLL Version ${sample.Native.Init.init()}');
//        var x = new sample.Native.Sample();
        //
  //      sample.Sample.testStatic();

        var xptr = Sample.construct();
        var x = xptr;
//        var x = xptr.get_ref();
        trace('x is ${x}');
        x.print();
        var y = x.funci(20);
        trace('y is ${y}');
        var aptr = x.makeA();
        var a = aptr;
        trace('Class A value ${a.a}');
        a.print();
        trace('Enum value ${sample.SampleEnum.SE_0}');
        trace('Enum value ${sample.SampleEnum.SE_1}');
  //      var b = x.makeB();
    //    b.print();
        trace("Done Sample Main");
    }
    
}