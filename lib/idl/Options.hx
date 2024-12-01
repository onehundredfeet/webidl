package idl;

import idl.CustomCode;

enum abstract Target(String) from String to String{
	var TargetHL = "hl";
	var TargetHXCPP = "hxcpp";
	var TargetJS = "js";
	var TargetJVM = "jvm";
	var TargetEmscripten = "emscripten";
}

enum abstract CPPFlavour(String) from String to String{
	var CPP_HXCPP = "hxcpp";
	var CPP_EMSCRIPTEN = "emscripten";
}

enum abstract BuildSystem(String) from String to String{
	var BuildNone = "none";
	var BuildHaxe = "haxe";
	var BuildCMake = "cmake";
	var BuildMake = "makefile";
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


	@:optional var customCode : CustomCode;
	@:optional var includes : Array<String>;
	// directories
	@:optional var buildDir : String;
	@:optional var glueDir : String;
	@:optional var hxDir : String;
	@:optional var installDir : String;


	@:optional var buildSystem : BuildSystem;
	@:optional var generateSource : Bool;
	@:optional var defaultConfig : String;
	@:optional var brew : Bool;
	@:optional var helperHeaderFile : String;
	@:optional var chopPrefix : String;
	@:optional var autoGC : Bool;
	@:optional var version : String;
	@:optional var architecture : Architecture;
	@:optional var cppFlavour : CPPFlavour;
}