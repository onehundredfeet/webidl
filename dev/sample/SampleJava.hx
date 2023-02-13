// This file is written entirely in the haxe language
package sample;

import java.lang.System;
import haxe.Int64;
import java.NativeArray;

//works in Java, but not JVM
@:classCode(
"static {
    System.loadLibrary(\"sample\");
}\n"
)

abstract SampleAbstract(Dynamic) {
    public function print() {
        trace ('Hello World!');
    }
}

class SampleNative {

    public var x : Int = 0;
    public var y : Int = 0;
    public var z : Float = 0.0;
    public var w : Single = 0.0;

    public var attr1(get, default) : Int;
    function get_attr1() : Int { return 0; }
    public var attr2(get, set) : Int;
    @:java.native function get_attr2() : Int;
    @:java.native function set_attr2(v : Int) : Int;

    @:java.native public static function staticNew() : SampleNative;
    static function bootstrap () : Bool {
        trace("Loading library...");
        java.lang.System.loadLibrary("sample");
        
        trace("done");
        return true;
    }
    static var lib = bootstrap();

    public function new() {
        trace("Hello World!");
        nativeNew(this);
    }
    @:java.native public function nativeNew(SampleNative );
    @:java.native public function finalize() : Void;
    @:java.native public function blurt() : Void;
    @:java.native public static function blurtStatic() : Void;
    @:java.native public function fi() : Int;
    @:java.native public function ff() : Float;
    @:java.native public function fl() : Int64;
    @:java.native public function fd() : Dynamic;
    @:java.native public function fs() : String;
    @:java.native public function fas() : Array<String>;
    @:java.native public function fsingle() : Single;
    @:java.native public function fnas() : NativeArray<Single>;
    @:java.native public function fnaobj() : NativeArray<String>;
    @:java.native public function fn_nativeArrayF(array : NativeArray<Single> ) : Void;
    @:java.native public function fn_ArrayF(array : Array<Single> ): Void;
    @:java.native public function fn_buffer(buf : java.nio.ByteBuffer ): Void;
}

class SampleJava {

    public static function main() {
        trace("Hello World!");
        var x = new SampleNative();
        x.blurt();
        SampleNative.blurtStatic();
    }
}