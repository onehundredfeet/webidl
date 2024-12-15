package idl;

import idl.Data;
import haxe.macro.Expr;

using StringTools;
using idl.macros.MacroTools;

import idl.HaxeGenerationTarget;

class HaxeGenerationTargetHXCPP extends HaxeGenerationTarget {
	function getTargetCondition():String {
		return "#if cpp";
	}

	public function makeNative(iname:String, midfix:String, name:String, argc:Null<Int>, p:haxe.macro.Expr.Position):Array<MetadataEntry> {
		return null;
	}

	function makeVectorType(t:TypeAttr, vt:Type, vdim:Int, isReturn:Bool):ComplexType {
		var isOut = t.attr != null && t.attr.contains(AOut);

		return switch (vt) {
			case TFloat:
				switch (vdim) {
					case 2: macro :hvector.Vec2;
					case 3: macro :hvector.Vec3;
					case 4: macro :hvector.Vec4;
					default: throw "Unsupported vector dimension" + vdim;
				}
			case TInt:
				switch (vdim) {
					case 2: macro :hvector.Int2;
					case 3: macro :hvector.Int3;
					case 4: macro :hvector.Int4;
					default: throw "Unsupported vector dimension" + vdim;
				}
			case TDouble:
				switch (vdim) {
					case 2: macro :hvector.Float2;
					case 3: macro :hvector.Float3;
					case 4: macro :hvector.Float4;
					default: throw "Unsupported vector dimension" + vdim;
				}

			default: throw "Unsupported vector type " + vt;
		};
	}

	function makeType(t:TypeAttr, isReturn:Bool):ComplexType {
		var isOut = t.attr != null && t.attr.contains(AOut);

		return switch (t.t) {
			case TVoid: macro :Void;
			case TChar: macro :cpp.Char;
			case TInt, TUInt: (isOut) ? macro :cpp.Reference<Int> : macro :Int;
			case TInt64: ((isOut ? (macro :cpp.Reference<haxe.Int64>) : (macro :haxe.Int64)));
			case TShort: macro :cpp.Char;
			case TFloat: ((isOut ? (macro :cpp.Reference<Single>) : (macro :Single)));
			case TDouble: ((isOut ? (macro :cpp.Reference<Float>) : (macro :Float)));
			case TBool: ((isOut ? (macro :cpp.Reference<Bool>) : (macro :Bool)));
			case TDynamic: macro :Dynamic;
			case TType: throw "Unsupported type TType";
			case THString: isReturn && false ? macro :hl.Bytes : macro :String;
			case TCString: macro :cpp.ConstPointer<cpp.Char>;
			case TStdString: macro :cpp.StdStringRef;
			case TAny: macro :idl.Types.Any;
			case TEnum(enumName): isReturn ? enumName.asComplexType() : macro :Int;
			case TStruct: throw "Unsupported type TType";
			case TBytes: macro :cpp.Pointer<cpp.Char>;
			case TVector(vt, vdim): makeVectorType(t, vt, vdim, isReturn);
			case TPointer(pt):
				switch (pt) {
					case TChar: macro :cpp.Pointer<cpp.Char>;
					case TInt: macro :cpp.Pointer<Int>;
					case TUInt: macro :cpp.Pointer<UInt>;
					case TFloat: macro :cpp.Pointer<Single>;
					case TDouble: macro :cpp.Pointer<Float>;
					case TBool: macro :cpp.Pointer<Bool>;
					case TShort: macro :cpp.Pointer<cpp.UInt16>;
					case TVector(vt, dim):
						switch (vt) {
							case TFloat: macro :cpp.Pointer<Single>;
							case TDouble: macro :cpp.Pointer<Float>;
							case TInt: macro :cpp.Pointer<Int>;
							default: throw "Unsupported array vector type " + vt;
						}
					default:
						throw 'Unsupported array type. Sorry ${pt}';
				}
			case TArray(at, _):
				switch (at) {
					case TChar: macro :Array<cpp.Char>;
					case TInt: macro :Array<Int>;
					case TUInt: macro :Array<UInt>;
					case TFloat: macro :Array<Single>;
					case TDouble: macro :Array<Float>;
					case TBool: macro :Array<Bool>;
					case TShort: macro :Array<cpp.UInt16>;
					case TVector(t, dim): switch (t) {
							case TInt: switch (dim) {
									case 2: macro :hvector.Int2Array;
									case 3: macro :hvector.Int3Array;
									case 4: macro :hvector.Int4Array;
									default: macro :Array<Int>;
								}
							case TFloat:
								switch (dim) {
									case 2: macro :hvector.Vec2Array;
									case 3: macro :hvector.Vec3Array;
									case 4: macro :hvector.Vec4Array;
									default: macro :Array<Single>;
								}
							case TDouble:
								switch (dim) {
									case 2: macro :hvector.Float2Array;
									case 3: macro :hvector.Float3Array;
									case 4: macro :hvector.Float4Array;
									default: macro :Array<Float>;
								}
							default: throw "Unsupported array type. Sorry";
						}
					case TCustom(id):
						if (_typeInfos.exists(id)) TPath({pack: ["cpp"], name: "NativeArray", params: [TPType(TPath(_typeInfos[id].path))]}); else
							TPath({pack: ["cpp"], name: "NativeArray", params: [TPType(TPath({pack: [], name: makeName(id)}))]});

					default:
						throw "Unsupported array type. Sorry";
				}
			//			var tt = makeType({ t : t, attr : [] });
			//			macro : idl.Types.NativePtr<$tt>;
			case TVoidPtr: macro :idl.Types.VoidPtr;
			case TFunction(ret, ta):
				var retT = makeType(ret, false);

				var args = ta.map((x) -> makeType(x, false));
				//			macro : GameControllerPtr -> hl.Bytes -> $retT;
				TFunction(args, retT);
			case TCustom(id):
				if (_typeInfos.exists(id)) {
					var ti:HaxeGenerationTypeInfo = _typeInfos.get(id);
					// trace('custom type ${id} has ${ti}');

					switch (ti.kind) {
						case DInterface(name, attrs, _):
							var ict = name.asComplexType();
							macro :cpp.Star<$ict>;
						default:
							TPath(ti.path);
					}
				} else {
					trace('no info for ${id}');
					TPath({pack: [], name: makeName(id)});
				}
		}
	}

	public function getInterfaceTypeDefinitions(iname:String, pack:Array<String>, dfields:Array<Field>, p:Position):Array<TypeDefinition> {
		var abstractNewField:Field = null;
		var staticNew:Field = null;
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
			staticNew.name = staticNew.name = "__construct";
			var newMeta:MetadataEntry = {name: ":native", params: ['new ${iname}'.asConstExpr()], pos: p};
			if (staticNew.meta == null) {
				staticNew.meta = [newMeta];
			} else {
				staticNew.meta = staticNew.meta.concat([newMeta]);
			}
			switch (staticNew.kind) {
				case FFun(f):
					var classNameExpr = iname.asComplexType();
					f.ret = macro :cpp.Star<$classNameExpr>;
				default:
					throw "Unsupported kind for new field";
			}
		}
		// var e : MetadataEntry;

		// var nativeName = makeName(iname) + "Extern";
		// var includes = opts.includes.map((x) -> {name: ":include", params:[x.asConstExpr()], pos: p});
		// var proxyDefn = {
		// 	pos: p,
		// 	pack: pack,
		// 	name: nativeName,
		// 	meta: includes.concat([{name: ":native", params:[makeName(iname).asConstExpr()], pos: p}]),
		// 	isExtern: true,
		// 	kind: TDClass(), //TDAbstract(macro :idl.Types.Ref, [], [macro :idl.Types.Ref], [macro :idl.Types.Ref]),
		// 	fields: dfields,
		// };

		// var proxyCT = nativeName.asComplexType();

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

		var includes = opts.includes.map((x) -> {name: ":include", params: [x.asConstExpr()], pos: p});
		var buildXML = "${" + opts.packageName.toUpperCase() + "_IDL_DIR}/" + opts.packageName + ".xml";

		var idlPathExpr = ("${" + opts.packageName.toUpperCase() + "_IDL_DIR}/" + opts.packageName + ".idl").asConstExpr();
		var macroBuildExpr = macro idl.macros.MacroTools.buildHXCPPIDLType($idlPathExpr);

		var nativeName = makeName(iname);

		var proxyName = nativeName + "Native";
		var fullProxyName = pack.join(".") + "." + proxyName;

		var proxyCT = fullProxyName.asComplexType();

		var classNativeDefn = {
			pos: p,
			pack: pack,
			name: proxyName,
			meta: [
				{name: ":native", params: [nativeName.asConstExpr()], pos: p},
				{name: ":structAccess", params: null, pos: p},
				{name: ":build", params: [macroBuildExpr], pos: p},
				// {name: ":buildXml", params:['<include name="${buildXML}"/>'.asConstExpr()], pos: p},
			],
			isExtern: true,
			kind: TDClass(), // TDAbstract(macro :idl.Types.Ref, [], [macro :idl.Types.Ref], [macro :idl.Types.Ref]),
			fields: dfields,
		}

		//ECall(EField(EConst(CIdent(name)).at(p), "fromIndex").at(p), [EConst(CInt("0")).at(p)]).at(p); // { expr : , pos : p };

		var fullConstructPath = fullProxyName + ".__construct";
		var proxyConstructExpr = fullfullProxyNameProxyName.asFieldAccess().asCallExpr([], p).asPrivateAccessExpr(p);
		var newWrapper = proxyConstructExpr.asFunctionField("new", [], proxyCT, p);

		var ptrCT = 'cpp.Star<${proxyCT}>'.asComplexType();

		var ptrDefn = {
			pos: p,
			pack: pack,
			name: nativeName + "Ptr",
			meta: [{name: ":forward", pos: p}, {name: ":forwardStatics", pos: p}],
			isExtern: false,
			kind: TDAbstract(ptrCT, [], [ptrCT], [ptrCT]),
			fields: [],
		};

		var abstractDefn = {
			pos: p,
			pack: pack,
			name: nativeName,
			meta: [{name: ":forward", pos: p}, {name: ":forwardStatics", pos: p}],
			isExtern: false,
			kind: TDAbstract(proxyCT, [], [proxyCT], [proxyCT]),
			fields: abstractNewField != null ? [newWrapper] : [],
		};

		return [classNativeDefn, abstractDefn];
	}

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

	public override function needsStubs():Bool {
		return false;
	}

	public override function addAttribute(iname:String, haxeName:String, f:idl.Data.Field, t:TypeAttr, p:Position):Array<haxe.macro.Field> {
		var attribFields = [];
		switch (t.t) {
			case TArray(at, sizeField):
				throw "Unsupported array type. Sorry";

			default:
				var tt = makeType(t, false);

				attribFields.push({
					pos: p,
					name: haxeName,
					meta: [],
					kind: FVar(tt),
					access: [APublic],
				});
		}

		return attribFields;
	}

	public override function makeEnum(name:String, attrs:Array<Attrib>, values:Array<String>, p:haxe.macro.Expr.Position) {
		var index = 0;
		function cleanEnum(v:String):String {
			return v.replace(":", "_");
		}
		var hasNamespace = true;
		var namespaceName = name;
		for (a in attrs) {
			switch (a) {
				case ANoNamespace:
					hasNamespace = !attrs.contains(ANoNamespace);
				case AInternal(namespace):
					namespaceName = namespace;
				default:
			}
		}
		var cfields:Array<haxe.macro.Expr.Field> = [
			for (v in values) {
				var fieldName = cleanEnum(v);
				var cppEnumName = hasNamespace ? namespaceName + "::" + fieldName : fieldName;
				{
					pos: p,
					name: fieldName,
					kind: FVar(null, {expr: EConst(CInt("" + (index++))), pos: p}),
					meta: [{name: ":native", params: [cppEnumName.asConstExpr()], pos: p}],
					access: [APublic, AStatic, AFinal, AInline, AExtern]
				}
			}
		];

		// //		Add Int Conversion
		// 		var ta:TypeAttr = {t: TInt, attr: [AStatic]};
		// 		var fn : Function = {args : [{name: "index", opt: false, t: {t: TInt, attr: []}}], ret: {t: TEnum(name), attr: []}, expr: null}
		// 		var toValue : Field = {
		// 			pos: p,
		// 			name: "indexToValue",
		// 			kind: FFun(fn),
		// 			meta: [],
		// 			access: [APublic, AStatic, AInline]
		// 		};
		// 		// var toValue = makeNativeFieldRaw(name, "indexToValue", p, [{name: "index", opt: false, t: {t: TInt, attr: []}}], ta, true);
		// 		cfields.push(toValue);

		// ta = {t: TInt, attr: [AStatic]};
		// var toIndex = makeNativeFieldRaw(name, "valueToIndex", p, [{name: "value", opt: false, t: {t: TInt, attr: []}}], ta, true);
		// cfields.push(toIndex);

		// ta = {t: TEnum(name), attr: [AStatic]};
		// var fromValue = makeNativeFieldRaw(name, "fromValue", p, [{name: "value", opt: false, t: {t: TInt, attr: []}}], ta, true);
		// cfields.push(fromValue);

		// ta = {t: TEnum(name), attr: [AStatic]};
		// var fromIndex = makeNativeFieldRaw(name, "fromIndex", p, [{name: "index", opt: false, t: {t: TInt, attr: []}}], ta, true);
		// cfields.push(fromIndex);

		// ta = {t: TInt, attr: []};
		// var toValue = makeNativeFieldRaw(name, "toValue", p, [], ta, true);
		// cfields.push(toValue);

		var enumT:TypeDefinition = {
			pos: p,
			pack: _pack,
			name: makeName(name),
			meta: [],
			kind: TDAbstract(macro :Int, []),
			fields: cfields,
		};

		var enumTP:TypePath = {
			pack: _pack,
			name: enumT.name
		};

		return {def: enumT, path: enumTP};
	}
} // @:functionCode - Used to inject platform-native code into a function.
// @:functionTailCode
// @:buildXml
// @:cppFileCode - Code to be injected into generated cpp file.
// @:cppInclude - File to be included in generated cpp file.
// @:cppNamespaceCode
// @:fileXml - Include a given XML attribute snippet in the Build.xml entry for the file.
// @:headerClassCode - Code to be injected into generated header file.
// @:headerCode - Code to be injected into generated header file.
// @:headerInclude - File to be included in generated header file.
// @:headerNamespaceCode - Code to be injected into generated header file.
// @:include
// @:noStack
// @:structAccess - Marks an extern class as using struct access (.) not pointer (->).
// @:stackOnly - Instances of this type can only appear on the stack.
// @:nonVirtual - Declares function to be non-virtual in cpp.
//    @:noDebug- Does not generate debug information even if --debug is set.
// @:nativeStaticExtension - Converts static function syntax into member call.
// @:nativeProperty - Use native properties which will execute even with dynamic usage.
// @:sourceFile - Source code filename for external class.
// @:objc
// @:objcProtocol
// @:decl
// extern
// @:native Rewrites the path of a type or class field during generation. See
// @:templatedCall - Indicates that the first parameter of static call should be treated as a template argument.
// @:unreflective - ?
// @:void - Use Cpp native void return type.
// @:nativeArrayAccess - When used on an extern class which implements haxe.ArrayAccess native array access syntax will be generated
// @:structAccess
// @:nativeArrayAccess
// @:include('vector')
// @:native('std::vector')
// extern class StdVector<T> implements ArrayAccess<cpp.Reference<T>> {
//     function new(size : Int);
//     function push_back(_v : T) : Void;
// }
// https://blog.aidanlee.uk/hxcpp-430/
