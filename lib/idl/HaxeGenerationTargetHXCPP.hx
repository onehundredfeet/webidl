package idl;

import idl.Data;
import haxe.macro.Expr;

using StringTools;
using idl.macros.MacroTools;

class HaxeGenerationTargetHXCPP extends HaxeGenerationTarget {

    function getTargetCondition() : String {
		return "#if cpp";
	}


    public function makeNative( iname : String, midfix : String, name : String, argc : Null<Int>, p:haxe.macro.Expr.Position ) : Array<MetadataEntry> {
        return null;
    }
    function makeVectorType( t : TypeAttr, vt : Type, vdim : Int, isReturn:Bool ): ComplexType {
        var isOut = t.attr != null && t.attr.contains(AOut);

		return switch(vt) {
			case TFloat: 
				switch(vdim) {
					case 2: macro : hvector.Vec2;
					case 3: macro : hvector.Vec3;
					case 4: macro : hvector.Vec4;
					default: throw "Unsupported vector dimension" + vdim;
				}
			case TInt:   
				switch(vdim) {
					case 2: macro : hvector.Int2;
					case 3: macro : hvector.Int3;
					case 4: macro : hvector.Int4;
					default: throw "Unsupported vector dimension" + vdim;
				}
			case TDouble:
				switch(vdim) {
					case 2: macro : hvector.Float2;
					case 3: macro : hvector.Float3;
					case 4: macro : hvector.Float4;
					default: throw "Unsupported vector dimension" + vdim;
				}
	
			default: throw "Unsupported vector type " + vt;
		};
	}
    function makeType( t : TypeAttr,isReturn:Bool ) : ComplexType {
		var isOut = t.attr != null && t.attr.contains(AOut);

		return switch( t.t ) {
		case TVoid: macro : Void;
		case TChar: macro : cpp.Char;
		case TInt, TUInt: (isOut) ? macro : cpp.Reference<Int> : macro : Int;
		case TInt64 : ((isOut  ? (macro : cpp.Reference<haxe.Int64>) : (macro : haxe.Int64)));
		case TShort: macro : cpp.Char;
		case TFloat: ((isOut  ? (macro : cpp.Reference<Single>) : (macro : Single))) ;
		case TDouble:((isOut  ? (macro : cpp.Reference<Float>) : (macro : Float))) ;
		case TBool: ((isOut  ? (macro : cpp.Reference<Bool>) : (macro : Bool))) ;
		case TDynamic: macro :Dynamic;
		case TType: throw "Unsupported type TType";
		case THString : isReturn && false? macro : hl.Bytes : macro : String;
		case TAny: macro : idl.Types.Any;
		case TEnum(enumName): isReturn ? enumName.asComplexType() : macro : Int;
		case TStruct: throw "Unsupported type TType";
		case TBytes: macro : cpp.Pointer<cpp.Char>;
		case TVector(vt, vdim): makeVectorType( t, vt, vdim, isReturn);
		case TPointer(pt):
			switch(pt) {
				case TChar: macro : cpp.Pointer<cpp.Char>;
				case TInt: macro :  cpp.Pointer<Int>;
				case TUInt: macro :  cpp.Pointer<UInt>;
				case TFloat:  macro : cpp.Pointer<Single>;
				case TDouble: macro :  cpp.Pointer<Float>;
				case TBool: macro : cpp.Pointer<Bool>;
				case TShort:  macro : cpp.Pointer<cpp.UInt16>;
				case TVector(vt, dim): 
					switch(vt) {
						case TFloat:macro : cpp.Pointer<Single>;
						case TDouble: macro : cpp.Pointer<Float>;
						case TInt: macro : cpp.Pointer<Int>;
							default: throw "Unsupported array vector type " + vt;
					}
				default:
					throw 'Unsupported array type. Sorry ${pt}';
			}
		case TArray(at, _):
			switch(at) {
				case TChar: macro : Array<cpp.Char>;
				case TInt: macro : Array<Int>;
				case TUInt: macro : Array<UInt>;
				case TFloat:  macro : Array<Single>;
				case TDouble: macro : Array<Float>;
				case TBool: macro : Array<Bool>;
				case TShort:  macro : Array<cpp.UInt16>;
				case TVector(t, dim): switch(t) {
					case TInt: switch(dim) {
						case 2: macro : hvector.Int2Array;
						case 3: macro : hvector.Int3Array;
						case 4: macro : hvector.Int4Array;
						default: macro : Array<Int>;
					}
					case TFloat: 
						switch(dim) {
							case 2: macro : hvector.Vec2Array;
							case 3: macro : hvector.Vec3Array;
							case 4: macro : hvector.Vec4Array;
							default: macro : Array<Single>;
						}	
                        case TDouble: 
                            switch(dim) {
                                case 2: macro : hvector.Float2Array;
                                case 3: macro : hvector.Float3Array;
                                case 4: macro : hvector.Float4Array;
                                default: macro : Array<Float>;
                            }	
					default: throw "Unsupported array type. Sorry";
				}
				case TCustom(id):
					if (typeNames.exists(id))
						TPath({pack:["cpp"], name: "NativeArray",params:[TPType( TPath( typeNames[id] ) )]});
					else
						TPath({pack:["cpp"], name: "NativeArray",params:[TPType( TPath({ pack : [], name : makeName(id) }) )]});

				default:
					throw "Unsupported array type. Sorry";
			}
//			var tt = makeType({ t : t, attr : [] });
//			macro : idl.Types.NativePtr<$tt>;
		case TVoidPtr: macro : idl.Types.VoidPtr;
		case TFunction(ret, ta): 
			var retT = makeType(ret, false);

			var args = ta.map( (x) -> makeType(x, false));
//			macro : GameControllerPtr -> hl.Bytes -> $retT;
			TFunction( args, retT);
		case TCustom(id): 
			if (typeNames.exists(id)) {
				TPath( typeNames[id]);
			}
			else
				TPath({ pack : [], name : makeName(id) });
		}
	}

	public function getInterfaceTypeDefinitions(iname:String, pack:Array<String>, dfields:Array<Field>, p:Position):Array<TypeDefinition> {


		var abstractNewField : Field = null;
		var staticNew : Field = null;
		for (df in dfields) {
			if (df.name == "new") {
				abstractNewField = df;
			} else if (df.name.startsWith("new")) {
				staticNew = df;
			}
		}
		if (abstractNewField != null) {
			dfields.remove(abstractNewField);
		}
		if (staticNew != null) {
			staticNew.name = staticNew.name = "construct";
			var newMeta : MetadataEntry = {name: ":native", params:['new ${iname}'.asConstExpr()], pos: p};
			if (staticNew.meta == null) {
				staticNew.meta = [newMeta];
			} else {
				staticNew.meta = staticNew.meta.concat([newMeta]);
			}
			switch(staticNew.kind) {
				case FFun(f):
					var classNameExpr = iname.asComplexType();
					f.ret = macro : cpp.Pointer<$classNameExpr>;
				default:
					throw "Unsupported kind for new field";
			}
		}
		//var e : MetadataEntry;

		// var proxyName = makeName(iname) + "Extern";
		// var includes = opts.includes.map((x) -> {name: ":include", params:[x.asConstExpr()], pos: p});
		// var proxyDefn = {
		// 	pos: p,
		// 	pack: pack,
		// 	name: proxyName,
		// 	meta: includes.concat([{name: ":native", params:[makeName(iname).asConstExpr()], pos: p}]),
		// 	isExtern: true,
		// 	kind: TDClass(), //TDAbstract(macro :idl.Types.Ref, [], [macro :idl.Types.Ref], [macro :idl.Types.Ref]),
		// 	fields: dfields,
		// };

		// var proxyCT = proxyName.asComplexType();

		// var abstractDefn = {
		// 	pos: p,
		// 	pack: pack,
		// 	name: makeName(iname),
		// 	meta: [{name: ":forward", pos: p}, {name: ":forwardStatics", pos: p}],
		// 	isExtern: false,
		// 	kind: TDAbstract(proxyCT, [], [proxyCT], [proxyCT]),
		// 	fields: abstractNewField != null ? [abstractNewField] : [],
		// };
		// return [proxyDefn, abstractDefn];

		var includes = opts.includes.map((x) -> {name: ":include", params:[x.asConstExpr()], pos: p});
		return [{
			pos: p,
			pack: pack,
			name:  makeName(iname) ,
			meta: includes.concat([{name: ":native", params:[makeName(iname).asConstExpr()], pos: p}]),
			isExtern: true,
			kind: TDClass(), //TDAbstract(macro :idl.Types.Ref, [], [macro :idl.Types.Ref], [macro :idl.Types.Ref]),
			fields: dfields,
		}];


// // By extending RGB we keep the same API as far as haxe is concerned, but store the data (not pointer)
// //  The native Reference class knows how to take the reference to the structure
// @:native("cpp.Reference<RGB>")
// extern class RGBRef extends RGB
// {
// }



// // By extending RGBRef, we can keep the same api, 
// //  rather than a pointer
// @:native("cpp.Struct<RGB>")
// extern class RGBStruct extends RGBRef
// {
// }

	}

	public override function needsStubs() : Bool {
        return false;
    }
}



//@:functionCode - Used to inject platform-native code into a function.
//@:functionTailCode
// @:buildXml
//@:cppFileCode - Code to be injected into generated cpp file.
//@:cppInclude - File to be included in generated cpp file.
//@:cppNamespaceCode
//@:fileXml - Include a given XML attribute snippet in the Build.xml entry for the file.
//@:headerClassCode - Code to be injected into generated header file.
//@:headerCode - Code to be injected into generated header file.
//@:headerInclude - File to be included in generated header file.
//@:headerNamespaceCode - Code to be injected into generated header file.
//@:include
//@:noStack
//@:structAccess - Marks an extern class as using struct access (.) not pointer (->).
//@:stackOnly - Instances of this type can only appear on the stack.
//@:nonVirtual - Declares function to be non-virtual in cpp.
//    @:noDebug- Does not generate debug information even if --debug is set.
//@:nativeStaticExtension - Converts static function syntax into member call.
//@:nativeProperty - Use native properties which will execute even with dynamic usage.
//@:sourceFile - Source code filename for external class.
//@:objc
//@:objcProtocol
//@:decl
// extern
// @:native Rewrites the path of a type or class field during generation. See 

//@:templatedCall - Indicates that the first parameter of static call should be treated as a template argument.

//@:unreflective - ?
//@:void - Use Cpp native void return type.

//@:nativeArrayAccess - When used on an extern class which implements haxe.ArrayAccess native array access syntax will be generated

// @:structAccess
// @:nativeArrayAccess
// @:include('vector')
// @:native('std::vector')
// extern class StdVector<T> implements ArrayAccess<cpp.Reference<T>> {
//     function new(size : Int);

//     function push_back(_v : T) : Void;
// }

// https://blog.aidanlee.uk/hxcpp-430/