package idl;

enum abstract Target(String) from String to String{
	var TargetHL = "hl";
	var TargetCPP = "cpp";
	var TargetJS = "js";
	var TargetJVM = "jvm";
}

enum abstract Architecture(String) from String to String{
	var ArchX86_64 = "x86_64";
	var ArchArm64 = "arm64";
	var ArchAll = "all";
}

typedef Options = {
	var idlFile : String;
	var nativeLib : String;
	var packageName : String; // usually the same as nativeLib
	var target : Target;
	@:optional var defaultConfig : String;
	@:optional var brew : Bool;
	@:optional var helperHeaderFile : String;
	@:optional var outputDir : String;
	@:optional var includeCode : String;
	@:optional var chopPrefix : String;
	@:optional var autoGC : Bool;
	@:optional var version : String;
	@:optional var architecture : Architecture;
}