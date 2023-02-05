package idl;

@:enum abstract Target(String) from String to String{
	var TargetHL = "hl";
	var TargetCPP = "cpp";
	var TargetJS = "js";
	var TargetJVM = "jvm";
}

typedef Options = {
	var idlFile : String;
	var nativeLib : String;
	var packageName : String; // usually the same as nativeLib
	var target : Target;
	@:optional var helperHeaderFile : String;
	@:optional var outputDir : String;
	@:optional var includeCode : String;
	@:optional var chopPrefix : String;
	@:optional var autoGC : Bool;
	@:optional var version : String;
}