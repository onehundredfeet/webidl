package sample;
import idl.Types;
#if hl

abstract Sample(idl.Types.Ref) from idl.Types.Ref to idl.Types.Ref {
	public var x(get, set) : Int;
	@:hlNative("sample", "Sample_get_x")
	function get_x():Int return 0;
	@:hlNative("sample", "Sample_set_x")
	function set_x(_v:Int):Int return 0;
	public var y(get, set) : Int;
	@:hlNative("sample", "Sample_get_y")
	function get_y():Int return 0;
	@:hlNative("sample", "Sample_set_y")
	function set_y(_v:Int):Int return 0;
	@:hlNative("sample", "Sample_new0")
	inline static function new0():Sample return null;
	public inline function new():Void this = new0();
	@:hlNative("sample", "Sample_funci1")
	inline public function funci(x:Int):Int return 0;
	@:hlNative("sample", "Sample_print0")
	inline public function print():Void { }
	@:hlNative("sample", "Sample_makeA0")
	inline public function makeA():SampleA return null;
	@:hlNative("sample", "Sample_gatherPtr2")
	inline public function gatherPtr(array:hl.BytesAccess<Single>, num:Int):Void { }
	@:hlNative("sample", "Sample_gatherArray2")
	inline public function gatherArray(array:hl.NativeArray<Single>, num:Int):Void { }
	@:hlNative("sample", "Sample_length0")
	inline public function length():Float return 0.;
	@:hlNative("sample", "Sample_delete")
	inline public function delete():Void { }
}
#end
