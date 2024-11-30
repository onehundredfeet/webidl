package sample;
import idl.Types;
#if hl

enum abstract SampleEnum(Int) {
	var SE_0 = 0;
	var SE_1 = 1;
	var SE_2 = 2;
	@:hlNative("sample", "SampleEnum_indexToValue1")
	inline public static function indexToValue(index:Int):Int return 0;
	@:hlNative("sample", "SampleEnum_valueToIndex1")
	inline public static function valueToIndex(value:Int):Int return 0;
	@:hlNative("sample", "SampleEnum_fromValue1")
	inline public static function fromValue(value:Int):SampleEnum return SampleEnum.fromIndex(0);
	@:hlNative("sample", "SampleEnum_fromIndex1")
	inline public static function fromIndex(index:Int):SampleEnum return SampleEnum.fromIndex(0);
	@:hlNative("sample", "SampleEnum_toValue0")
	inline public function toValue():Int return 0;
}
#end
