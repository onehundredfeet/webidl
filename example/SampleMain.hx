// This file is written entirely in the Haxe language
package ;



class SampleMain {
    static function main() {
        trace("Hello, world!");
        var x = new sample.Native.Sample();

        var a = x.makeA();
        var b = x.makeB();
        b.print();
        trace("Done");
    }
    
}