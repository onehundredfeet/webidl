package sample;
import idl.Types;
#if hl

abstract SampleB(idl.Types.Ref) from idl.Types.Ref to idl.Types.Ref {
	public var b(get, set) : Float;
	@:hlNative("sample", "SampleB_get_b")
	function get_b():Float return 0.;
	@:hlNative("sample", "SampleB_set_b")
	function set_b(_v:Float):Float return 0.;
	@:hlNative("sample", "SampleB_print0")
	inline public function print():Void { }
	@:hlNative("sample", "SampleB_delete")
	inline public function delete():Void { }
}
#end
