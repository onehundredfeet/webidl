// This file is written entirely in the Haxe language
package ;

import haxe.zip.Uncompress;
import haxe.zip.Compress;

import sample.Sample;


class SampleMain {
    static function main() {
        trace("Forcing bootstrap");
        var p = Compress.run(haxe.io.Bytes.ofString("Hello World"), 1);
        trace(Uncompress.run(p));
        //trace('DLL Version ${sample.Native.Init.init()}');
//        var x = new sample.Native.Sample();
        //
  //      sample.Sample.testStatic();

        var x = Sample.construct();
        trace('x is ${x}');
        x.print();
        var y = x.funci(20);
        trace('y is ${y}');
        var a = x.makeA();
        trace('Class A value ${a.a}');
        a.print();
  //      var b = x.makeB();
    //    b.print();
        trace("Done Sample Main");
    }
    
}