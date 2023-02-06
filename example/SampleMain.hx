// This file is written entirely in the Haxe language
package ;



class SampleMain {
    static function main() {
        trace("Forcing bootstrap");
        trace('DLL Version ${sample.Native.Init.init()}');
        var x = new sample.Native.Sample();
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