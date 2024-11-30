package sample;
import idl.Types;
#if hl

abstract SampleA(idl.Types.Ref) from idl.Types.Ref to idl.Types.Ref {
	public var a(get, set) : Single;
	@:hlNative("sample", "SampleA_get_a")
	function get_a():Single return 0.;
	@:hlNative("sample", "SampleA_set_a")
	function set_a(_v:Single):Single return 0.;
	public var et(get, set) : SampleEnum;
	@:hlNative("sample", "SampleA_get_et")
	function get_et():SampleEnum return cast(0, SampleEnum);
	@:hlNative("sample", "SampleA_set_et")
	function set_et(_v:SampleEnum):SampleEnum return cast(0, SampleEnum);
	@:hlNative("sample", "SampleA_new0")
	inline static function new0():SampleA return null;
	public inline function new():Void this = new0();
	@:hlNative("sample", "SampleA_print0")
	inline public function print():Void { }
	@:hlNative("sample", "SampleA_getEnum1")
	inline public function getEnum(p:SampleEnum):SampleEnum return cast(0, SampleEnum);
	@:hlNative("sample", "SampleA_delete")
	inline public function delete():Void { }
}
#end
