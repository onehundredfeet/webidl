package webidl;

import haxe.macro.Expr.Function;
import webidl.Data;

class Generate {
	static var HEADER_EMSCRIPTEN = "

#include <emscripten.h>
#define HL_PRIM
#define HL_NAME(n)	EMSCRIPTEN_KEEPALIVE eb_##n
#define DEFINE_PRIM(ret, name, args)
#define _OPT(t) t*
#define _GET_OPT(value,t) *value


";

	static var HEADER_HL = "

#include <hl.h>

// Need to link in helpers
HL_API hl_type hltx_ui16;

#define _IDL _BYTES
#define _OPT(t) vdynamic *
#define _GET_OPT(value,t) (value)->v.t


";

	static var HEADER_NO_GC = "

#define alloc_ref(r, _) r
#define alloc_ref_const(r,_) r
#define _ref(t)			t
#define _unref(v)		v
#define free_ref(v) delete (v)
#define HL_CONST const

	";

	static var HEADER_GC = "

template <typename T> struct pref {
	void (*finalize)( pref<T> * );
	T *value;
};

#define _ref(t) pref<t>
#define _unref(v) v->value
#define alloc_ref(r,t) _alloc_ref(r,finalize_##t)
#define alloc_ref_const(r, _) _alloc_const(r)
#define HL_CONST

template<typename T> void free_ref( pref<T> *r ) {
	if( !r->finalize ) hl_error(\"delete() is not allowed on const value.\");
	delete r->value;
	r->value = NULL;
	r->finalize = NULL;
}

// Float vector
struct _hl_float2 {
	float x;
	float y;
};

struct _hl_float3 {
	float x;
	float y;
	float z;
};

struct _hl_float4 {
	float x;
	float y;
	float z;
	float w;
};

// int vector
struct _hl_int2 {
	int x;
	int y;
};

struct _hl_int3 {
	int x;
	int y;
	int z;
};

struct _hl_int4 {
	int x;
	int y;
	int z;
	int w;
};

// double vector
struct _hl_double2 {
	double x;
	double y;
};

struct _hl_double3 {
	double x;
	double y;
	double z;
};

struct _hl_double4 {
	double x;
	double y;
	double z;
	double w;
};

inline void testvector(_hl_float3 *v) {
  printf(\"v: %f %f %f\\n\", v->x, v->y, v->z);
}
template<typename T> pref<T> *_alloc_ref( T *value, void (*finalize)( pref<T> * ) ) {
	if (value == nullptr) return nullptr;
	pref<T> *r = (pref<T>*)hl_gc_alloc_finalizer(sizeof(pref<T>));
	r->finalize = finalize;
	r->value = value;
	return r;
}

template<typename T> pref<T> *_alloc_const( const T *value ) {
	if (value == nullptr) return nullptr;
	pref<T> *r = (pref<T>*)hl_gc_alloc_noptr(sizeof(pref<T>));
	r->finalize = NULL;
	r->value = (T*)value;
	return r;
}

inline static varray* _idc_alloc_array(float *src, int count) {
	if (src == nullptr) return nullptr;

	varray *a = NULL;
	float *p;
	a = hl_alloc_array(&hlt_f32, count);
	p = hl_aptr(a, float);

	for (int i = 0; i < count; i++) {
		p[i] = src[i];
	}
	return a;
}


inline static varray* _idc_alloc_array(int *src, int count) {
	if (src == nullptr) return nullptr;

	varray *a = NULL;
	int *p;
	a = hl_alloc_array(&hlt_i32, count);
	p = hl_aptr(a, int);

	for (int i = 0; i < count; i++) {
		p[i] = src[i];
	}
	return a;

}

inline static varray* _idc_alloc_array(double *src, int count) {
	if (src == nullptr) return nullptr;

	varray *a = NULL;
	double *p;
	a = hl_alloc_array(&hlt_f64, count);
	p = hl_aptr(a, double);

	for (int i = 0; i < count; i++) {
		p[i] = src[i];
	}
	return a;
}


inline static varray* _idc_alloc_array(const unsigned short *src, int count) {
	if (src == nullptr) return nullptr;

	varray *a = NULL;
	unsigned short *p;
	a = hl_alloc_array(&hltx_ui16, count);
	p = hl_aptr(a, unsigned short);

	for (int i = 0; i < count; i++) {
		p[i] = src[i];
	}
	return a;
}

inline static varray* _idc_alloc_array(unsigned short *src, int count) {
	if (src == nullptr) return nullptr;

	varray *a = NULL;
	unsigned short *p;
	a = hl_alloc_array(&hltx_ui16, count);
	p = hl_aptr(a, unsigned short);

	for (int i = 0; i < count; i++) {
		p[i] = src[i];
	}
	return a;
}

inline static void _idc_copy_array( float *dst, varray *src, int count) {
	float *p = hl_aptr(src, float);
	for (int i = 0; i < count; i++) {
		dst[i] = p[i];
	}
}

inline static void _idc_copy_array( varray *dst, float *src,  int count) {
	float *p = hl_aptr(dst, float);
	for (int i = 0; i < count; i++) {
		p[i] = src[i];
	}
}


inline static void _idc_copy_array( int *dst, varray *src, int count) {
	int *p = hl_aptr(src, int);
	for (int i = 0; i < count; i++) {
		dst[i] = p[i];
	}
}

inline static void _idc_copy_array( unsigned short *dst, varray *src) {
	unsigned short *p = hl_aptr(src, unsigned short);
	for (int i = 0; i < src->size; i++) {
		dst[i] = p[i];
	}
}

inline static void _idc_copy_array( const unsigned short *cdst, varray *src) {
	unsigned short *p = hl_aptr(src, unsigned short);
	unsigned short *dst = (unsigned short *)cdst;
	for (int i = 0; i < src->size; i++) {
		dst[i] = p[i];
	}
}

inline static void _idc_copy_array( varray *dst, int *src,  int count) {
	int *p = hl_aptr(dst, int);
	for (int i = 0; i < count; i++) {
		p[i] = src[i];
	}
}


inline static void _idc_copy_array( double *dst, varray *src, int count) {
	double *p = hl_aptr(src, double);
	for (int i = 0; i < count; i++) {
		dst[i] = p[i];
	}
}

inline static void _idc_copy_array( varray *dst, double *src,  int count) {
	double *p = hl_aptr(dst, double);
	for (int i = 0; i < count; i++) {
		p[i] = src[i];
	}
}


";

	static var HEADER_NATIVE_TYPES = "
class FloatArray
{
public:
	FloatArray() {}

	FloatArray(int size)
	{
		list = new float[size];
	}

	float Get(int index)
	{
		return list[index];
	}

	void Set(int index, float value)
	{
		list[index] = value;
	}

	float* GetPtr() {
		return list;
	}

private:
	float* list;
};

class IntArray
{
public:
	IntArray() {}

	IntArray(int size)
	{
		list = new int[size];
	}

	int Get(int index)
	{
		return list[index];
	}

	void Set(int index, int value)
	{
		list[index] = value;
	}

	int* GetPtr() {
		return list;
	}

private:
	int* list;
};

class CharArray
{
public:
	CharArray() {}

	CharArray(int size)
	{
		list = new unsigned char[size];
	}

	char Get(int index)
	{
		return list[index];
	}

	void Set(int index, unsigned char value)
	{
		list[index] = value;
	}

	unsigned char* GetPtr() {
		return list;
	}

private:
	unsigned char* list;
};

class ShortArray
{
public:
    ShortArray() {}

    ShortArray(int size)
	{
		list = new unsigned short[size];
	}

	short Get(int index)
	{
		return list[index];
	}

	void Set(int index, unsigned short value)
	{
		list[index] = value;
	}

	unsigned short* GetPtr() {
		return list;
	}

private:
	unsigned short* list;
};
	";

	static function initOpts(opts:Options) {
		if (opts.outputDir == null)
			opts.outputDir = "";
		else if (!StringTools.endsWith(opts.outputDir, "/"))
			opts.outputDir += "/";
	}

	public static function generateCpp(opts:Options) {
		initOpts(opts);

		var file = opts.idlFile;
		var content = sys.io.File.getBytes(file);
		var parse = new webidl.Parser();
		var decls = null;
		var gc = opts.autoGC;
		try {
			decls = parse.parseFile(file, new haxe.io.BytesInput(content));
		} catch (msg:String) {
			throw msg + "(" + file + " line " + parse.line + ")";
		}
		var output = new StringBuf();
		function add(str:String) {
			output.add(str.split("\r\n").join("\n") + "\n");
		}
		add("#ifdef EMSCRIPTEN");
		add("");
		add(StringTools.trim(HEADER_EMSCRIPTEN));
		add(StringTools.trim(HEADER_NO_GC));
		add("");
		add("#else");
		add("");
		add('#define HL_NAME(x) ${opts.nativeLib}_##x');
		add(StringTools.trim(HEADER_HL));
		add(StringTools.trim(gc ? HEADER_GC : HEADER_NO_GC));
		add("");
		add("#endif");
		if (opts.includeCode != null) {
			add("");
			add(StringTools.trim(opts.includeCode));
		}
		add("");
		add("");
		add(StringTools.trim(HEADER_NATIVE_TYPES));
		add("");
		add("");
		add('extern "C" {');
		add("");

		var typeNames = new Map();
		var enumNames = new Map();

		// ignore "JSImplementation" interfaces (?)
		for (d in decls.copy())
			switch (d.kind) {
				case DInterface(_, attrs, _):
					for (a in attrs)
						switch (a) {
							case AJSImplementation(_):
								decls.remove(d);
								break;
							default:
						}
				default:
			}

		for (d in decls) {
			switch (d.kind) {
				case DInterface(name, attrs, _):
					var prefix = "";
					var intName = name;
					for (a in attrs)
						switch (a) {
							case APrefix(name): prefix = name;
							case AInternal(iname): intName = iname;
							default:
						}

					var fullName = "_ref(" + prefix + intName + ")*";
					typeNames.set(name, {full: fullName, constructor: prefix + intName});
					if (attrs.indexOf(ANoDelete) >= 0)
						continue;
					add('static void finalize_$name( $fullName _this ) { free_ref(_this); }');
					add('HL_PRIM void HL_NAME(${name}_delete)( $fullName _this ) {\n\tfree_ref(_this);\n}');
					add('DEFINE_PRIM(_VOID, ${name}_delete, _IDL);');
				case DEnum(name, attrs, values):
					enumNames.set(name, true);
					typeNames.set(name, {full: "int", constructor: null});

					var etname = name;
					for (a in attrs) {
						switch (a) {
							case AInternal(iname): etname = iname;
							default:
						}
					}
					add('static $etname ${name}__values[] = { ${values.join(",")} };');
					add('HL_PRIM int HL_NAME(${name}_toValue0)( int idx ) {\n\treturn ${name}__values[idx];\n}');
					add('DEFINE_PRIM(_I32, ${name}_toValue0, _I32);');
					add('HL_PRIM int HL_NAME(${name}_indexToValue0)( int idx ) {\n\treturn ${name}__values[idx];\n}');
					add('DEFINE_PRIM(_I32, ${name}_indexToValue0, _I32);');
					add('HL_PRIM int HL_NAME(${name}_valueToIndex0)( int value ) {\n\tfor( int i = 0; i < ${values.length}; i++ ) if ( value == (int)${name}__values[i]) return i; return -1;\n}');
					add('DEFINE_PRIM(_I32, ${name}_valueToIndex0, _I32);');
				case DTypeDef(name, attrs, type):
				case DImplements(_):
			}
		}

		function getEnumName(t:webidl.Data.Type) {
			return switch (t) {
				case TCustom(id): enumNames.exists(id) ? id : null;
				default: null;
			}
		}

		function makeType(t:webidl.Data.TypeAttr, isReturn:Bool = false) {
			var x = switch (t.t) {
				case TChar: "unsigned char";
				case TFloat: "float";
				case TDouble: "double";
				case TShort: "unsigned short";
				case TInt64: "int64_t";
				case TUInt: "unsigned int";
				case TInt: "int";
				case TVoid: "void";
				case TAny, TVoidPtr: "void*";
				case TArray(_, _): "varray*"; // makeType(t) + "vdynamic *"; // This is an array of OBJECTS, likely a bug here
				case TPointer(t): "vbyte*";
				case TBool: "bool";
				case TEnum(_): "int";
				case THString: "vstring *";
				case TBytes: "vbyte*";
				case TCustom(id): {
						var t = typeNames.get(id);
						if (t == null) {
							throw "Unsupported type " + id;
						} else {
							typeNames.get(id).full;
						}
					}
				case TVector(vt, vdim):
					switch (vt) {
						case TFloat: "_hl_float" + vdim + "*";
						case TDouble: "_hl_double" + vdim + "*";
						case TInt: "_hl_int" + vdim + "*";
						default: throw "Unsupported vector type";
					}
				default:
					throw "Unknown type " + t;
			}
			return t.attr.contains(AOut) ? x + "*" : x;
		}

		function defType(t:TypeAttr, isReturn:Bool = false) {
			var x = switch (t.t) {
				case TChar: "_I8";
				case TFloat: "_F32";
				case TDouble: "_F64";
				case TShort: "_I16";
				case TInt64: "_I64";
				case TUInt: "_I32";
				case TInt: "_I32";
				case TEnum(_): "_I32";
				case TVoid: "_VOID";
				case TPointer(_), TAny, TVoidPtr: "_BYTES";
				case TArray(_, _): "_ARR";
				case TBool: "_BOOL";
				case TBytes: "_BYTES";
				case TVector(t, dim): "_STRUCT";
				case THString: "_STRING";
				case TCustom(name): enumNames.exists(name) ? "_I32" : "_IDL";
			}

			return t.attr.contains(AOut) ? "_REF(" + x + ")" : x;
		}

		function dynamicAccess(t) {
			return switch (t) {
				case TChar: "c";
				case TFloat: "f";
				case TDouble: "d";
				case TShort: "ui16";
				case TInt64: "i64";
				case TInt: "i";
				case TUInt: "i";
				case TBool: "b";
				default: throw "assert";
			}
		}

		function makeTypeDecl(td:TypeAttr, isReturn:Bool = false) {
			var prefix = "";
			for (a in td.attr) {
				switch (a) {
					case AConst:
						prefix += "HL_CONST ";
					default:
				}
			}
			return prefix + makeType(td, isReturn);
		}

		function isDyn(arg:{opt:Bool, t:TypeAttr}) {
			return arg.opt && !arg.t.t.match(TCustom(_));
		}

		for (d in decls) {
			switch (d.kind) {
				case DInterface(name, attrs, fields):
					for (f in fields) {

						switch (f.kind) {
							case FMethod(margs, ret):
								var isConstr = f.name == name;
								var args = (isConstr || ret.attr.indexOf(AStatic) >= 0) ? margs : [
									{
										name: "_this",
										t: {t: TCustom(name), attr: []},
										opt: false
									}
								].concat(margs);

								var returnField:String = null;
								var returnType:TypeAttr;
								var ignore:Array<String> = [];

								for (a in args) {
									for (attr in a.t.attr) {
										switch (attr) {
											case AReturn:
												returnField = a.name;
												returnType = a.t;
												ignore.push(a.name);
											case ASubstitute(_):
												ignore.push(a.name);
											default:
										}
									}
								}

								var tret = isConstr ? {t: TCustom(name), attr: []} : ret;
								var isIndexed = tret.attr.contains(AIndexed);

								// Static functions needs the exact number of arguments as function suffix. Otherwise C++ compilation will fail.
								var argsSuffix = (ret.attr.indexOf(AStatic) >= 0) ? args.length : args.length - 1;
								var funName = name + "_" + (isConstr ? "new" + args.length : f.name + argsSuffix);

								// var staticPrefix = (attrs.indexOf(AStatic) >= 0) ? "static" : ""; ${staticPrefix}
								output.add('HL_PRIM ${makeTypeDecl(returnField == null ? tret : returnType, true)} HL_NAME($funName)(');
								var first = true;

								for (a in args) {
									if (!ignore.contains(a.name)) {
										if (first)
											first = false
										else
											output.add(", ");
										switch (a.t.t) {
											case TArray(t, sizeField):
												output.add(makeType(a.t));
											default:
												if (isDyn(a)) {
													// output.add("_OPT(" + makeType(a.t.t) + ")");
													output.add("_OPT(" + makeType({t: a.t.t, attr: a.t.attr}) + ")");
												} else {
													// output.add(makeType(a.t.t));
													output.add(makeType({t: a.t.t, attr: a.t.attr}));
													// Add '&' for referenced primitive types
													for (attr in a.t.attr) {
														switch (attr) {
															case ARef:
																switch (a.t.t) {
																	case TChar, TInt, TShort, TFloat, TDouble,TBool: output.add("&"); // Reference primitive types with &
																	default: output.add(""); // Do nothung for custom types
																}
															default:
														}
													}
												}
										}
										output.add(" " + a.name);
									}
								}
								add(') {');

								function addCall(margs:Array<{name:String, opt:Bool, t:TypeAttr}>) {
									// preamble
									var preamble = returnField != null;

									if (returnField != null) {
										output.add(makeType(returnType) + " __tmpret;");
									}

									for (a in margs) {
										switch (a.t.t) {
											case THString:
												preamble = true;
												if (!a.t.attr.contains(AHString)) {
													output.add("auto " + a.name + "__cstr = (" + a.name + " == nullptr) ? nullptr : hl_to_utf8( " + a.name
														+ "->bytes ); // Should be garbage collected\n\t");
												}
											default:
										}
									}
									var retCast = "";
									var getter = "";
									for (a in tret.attr) {
										switch (a) {
											case AValidate(expr):
												preamble = true;
											case ACast(t):
												retCast = "(" + t + ")";
											case AGet(g):
												getter = g;
											default:
										}
									}

									var refRet = null;
									var enumName = getEnumName(tret.t);

									var isRef = ret.attr.contains(ARef);
									var isValue = ret.attr.contains(AValue);
									var isConst = ret.attr.contains(AConst);
									var isCustomType = ret.t.match(TCustom(_));

									if (isConstr) {
										refRet = name;
										if (preamble) {
											output.add('auto ___retvalue = alloc_ref(${retCast}(new ${typeNames.get(refRet).constructor}(');
										} else {
											output.add('return alloc_ref(${retCast}(new ${typeNames.get(refRet).constructor}(');
										}
									} else {
										if (tret.t != TVoid)
											if (preamble)
												output.add("auto ___retvalue = ");
											else
												output.add("return ");

										if (isRef || isValue || isCustomType) {
											refRet = switch (tret.t) {
												case TCustom(id): id;
												default: throw "assert";
											}
										}

										if (enumName != null) {
											output.add('HL_NAME(${enumName}_valueToIndex0)(');
										} else if (isCustomType) {
											if (isRef && isConst) {
												output.add('alloc_ref_const(${retCast}${getter}&('); // we shouldn't call delete() on this one !
											} else if (isValue) {
												output.add('alloc_ref(${retCast}new ${typeNames.get(refRet).constructor}(${getter}(');
											} else if (isConst) {
												output.add('alloc_ref_const(${retCast}${getter}(');
											} else {
												output.add('alloc_ref(${retCast}${getter}(');
											}
										} else {
											output.add('${retCast}${getter}(');
										}

										switch (f.name) {
											case "op_mul":
												output.add("*_unref(_this) * (");
											case "op_add":
												output.add("*_unref(_this) + (");
											case "op_sub":
												output.add("*_unref(_this) - (");
											case "op_div":
												output.add("*_unref(_this) / (");
											case "op_mulq":
												output.add("*_unref(_this) *= (");
											default:
												var callName = f.name;

												for (a in ret.attr) {
													switch (a) {
														case AInternal(name):
															callName = name;
														default:
													}
												}

												if (ret.attr.contains(AStatic))
													output.add(callName + "(");
												else if (ret.attr.indexOf(ACObject) >= 0)
													output.add(callName + "( _unref(_this) ");
												else
													output.add("_unref(_this)->" + callName + (isIndexed ? "[" : "("));
										}
									}
									var first = (ret.attr.indexOf(ACObject) >= 0 ? false : true);

									// Actually process arguments for call
									for (a in margs) {
										var skip = false;
										if (first)
											first = false
										else
											output.add(", ");

										var argGetter = null;
										for (attr in a.t.attr) {
											switch (attr) {
												case ACast(type):
													output.add("(" + type + ")"); // unref
												case ASubstitute(expression):
													output.add(expression);
													skip = true;
													break;
												case AGet(expr):
													argGetter = expr;
												case ADeref:
													argGetter = "*";
												case ARef:
													switch(a.t.t){
														case TChar, TInt, TShort, TFloat, TDouble,TBool: output.add(""); // Reference primitive types don't need any symbol
														default: output.add("*"); // Unreference custom type
													}			

												default:
											}
										}

										if (skip) continue;

										if (argGetter != null) {
											output.add(argGetter + " (");
										}
										if (a.name == returnField) {
											output.add('&__tmpret');
										} else {
											var e = getEnumName(a.t.t);
											if (e != null)
												output.add('${e}__values[${a.name}]');
											else
												switch (a.t.t) {
													case TArray(t, sizefield):
														output.add('hl_aptr(${a.name},${makeTypeDecl({t: t, attr : a.t.attr})})');
													case TPointer(t):
														output.add('(${makeTypeDecl({t: t, attr : a.t.attr})} *)${a.name}');
													case TCustom(st):
														output.add('_unref(${a.name})');
														if (st == 'FloatArray' || st == "IntArray" || st == "CharArray" || st == "ShortArray") {
															output.add("->GetPtr()");
														}		
													case TVector(vt, vdim):
														output.add('(${makeTypeDecl({t: vt, attr : a.t.attr})}*)${a.name}');
													case THString:
														if (!a.t.attr.contains(AHString))
															output.add(a.name + "__cstr");
														else 
															output.add(a.name);
													default:
														if (isDyn(a)) {
															output.add("_GET_OPT(" + a.name + "," + dynamicAccess(a.t.t) + ")");
														} else
															output.add(a.name);
												}
										}

										if (argGetter != null) {
											output.add(")");
										}

									}

									if (enumName != null)
										output.add(')');
									else if (refRet != null)
										output.add((isIndexed ? "]" : ")") + (isValue ? ')' : '') + '),$refRet');
									else
										output.add(')');
									add(");");

									// post amble
									if (preamble) {
										for (a in margs) {
											switch (a.t.t) {
												case THString:
												// output.add("\tfree(" + a.name + "__cstr);\n");
												default:
											}
										}

										// Check for throw
										for (b in ret.attr) {
											switch (b) {
												case AValidate(expr):
													for (a in ret.attr) {
														switch (a) {
															case AThrow(msg):
																output.add("if (___retvalue != " + expr + ") hl_throw(" + msg + ");");
															default:
														}
													}
												default:
											}
										}

										if (tret.t != TVoid)
											if (returnField != null) {
												add("\treturn __tmpret;");
											} else {
												add("\treturn ___retvalue;");
											}
									}
								} // end add call

								var hasOpt = false;
								for (i in 0...margs.length)
									if (margs[i].opt) {
										hasOpt = true;
										break;
									}
								if (hasOpt) {
									for (i in 0...margs.length)
										if (margs[i].opt) {
											add("\tif( !" + margs[i].name + " )");
											output.add("\t\t");
											addCall(margs.slice(0, i));
											add("\telse");
										}
									output.add("\t\t");
									addCall(margs);
								} else {
									output.add("\t");
									addCall(margs);
								}
								add('}');
								output.add('DEFINE_PRIM(${defType(tret, true)}, $funName,');
								for (a in args) {
									if (!ignore.contains(a.name)) {
										output.add(' ' + (isDyn(a) ? "_NULL(" + defType(a.t) + ")" : defType(a.t)));
									}
								}
								add(');');
								add('');
						
						case FAttribute(t):
							var isVal = t.attr.indexOf(AValue) >= 0;
							var isIndexed = t.attr.contains(AIndexed);
							var isReadOnly = t.attr.contains(AReadOnly);
							var needsGetter = true;
							var needsSetter = !isReadOnly;

							var tname = switch (t.t) {
								case TCustom(id): id;
								default: null;
							};

							var vt:Type = null;
							var vta:TypeAttr = null;
							var vdim = 0;

							var isVector = switch (t.t) {
								case TVector(vvt, vvdim):
									vt = vvt;
									vdim = vvdim;
									vta = {t: vt, attr: t.attr};
									true;
								default: false;
							}

							var at:Type = null;
							var al:String = null;
							var isArray = switch (t.t) {
								case TArray(aat, aal):
									at = aat;
									al = aal;
									true;
								default: false;
							}

							var pt:Type = null;
							var isPointer = switch (t.t) {
								case TPointer(ppt):
									pt = ppt;
									true;
								default: false;
							}

							var isRef = tname != null;
							var enumName = getEnumName(t.t);
							var isConst = t.attr.indexOf(AConst) >= 0;

							// Translate name
							var internalName = f.name;
							var getter:String = null;
							var setter:String = null;

							for (a in t.attr) {
								switch (a) {
									case AInternal(name): internalName = name;
									case AGet(name): getter = name;
									case ASet(name): setter = name;
									default:
								}
							}
							var td = defType(t, true);

							// Get
							if (needsGetter) {
								add('HL_PRIM ${makeTypeDecl(t, true)} HL_NAME(${name}_get_${f.name})( ${typeNames.get(name).full} _this ) {');

								if (isVector) {
									add('\treturn (${makeTypeDecl(t)} )${(getter == null) ? "" : getter}(_unref(_this)->${internalName});');

									//									add('\treturn _idc_alloc_array(${(getter == null) ? "" : getter}(_unref(_this)->${internalName}),${vdim});');
								} else if (getter != null)
									add('\treturn ${getter}(_unref(_this)->${internalName});');
								else if (enumName != null)
									add('\treturn HL_NAME(${enumName}_valueToIndex0)(_unref(_this)->${internalName});');
								else if (isVal) {
									var fname = typeNames.get(tname).constructor;
									add('\treturn alloc_ref(new $fname(_unref(_this)->${f.name}),$tname);');
								} else if (isRef)
									add('\treturn alloc_ref${isConst ? '_const' : ''}(_unref(_this)->${f.name},$tname);');
								else if (isPointer) {
									add('\treturn (vbyte *)(&_unref(_this)->${internalName}[0]);');
								} else if (isArray) {
									add('\treturn _idc_alloc_array(&_unref(_this)->${internalName}[0], _unref(_this)->${al}); // This is wrong, needs to copy');
								} else {
									add('\treturn _unref(_this)->${internalName};');
								}
								add('}');

								if (isVector) {
									// Add vector getter
									add('HL_PRIM void HL_NAME(${name}_get${f.name}v)( ${typeNames.get(name).full} _this, ${makeTypeDecl(t)} value ) {');
									add('\t ${makeTypeDecl(vta)} *src = (${makeTypeDecl(vta)}*) & ${(getter == null) ? "" : getter}(_unref(_this)->${internalName})[0];');
									add('\t ${makeTypeDecl(vta)} *dst = (${makeTypeDecl(vta)}*) value;');
									add('\t${[for (c in 0...vdim) 'dst[$c] = src[${c}];'].join(' ')}');
									add('}');

									add('DEFINE_PRIM(_VOID,${name}_get${f.name}v,_IDL _STRUCT  );');
								}

								add('DEFINE_PRIM(${defType(t, true)},${name}_get_${f.name},_IDL);');
							}

							if (needsSetter) {
								// Set
								add('HL_PRIM ${makeTypeDecl(t)} HL_NAME(${name}_set_${f.name})( ${typeNames.get(name).full} _this, ${makeTypeDecl(t)} value ) {');

								if (isVector) {
									add('\t ${makeTypeDecl(vta)} *dst = (${makeTypeDecl(vta)}*) & ${(getter == null) ? "" : getter}(_unref(_this)->${internalName})[0];');
									add('\t ${makeTypeDecl(vta)} *src = (${makeTypeDecl(vta)}*) value;');
									add('\t${[for (c in 0...vdim) 'dst[$c] = src[${c}];'].join(' ')}');
									//									add('\t_idc_copy_array( ${(getter == null) ? "" : getter}(_unref(_this)->${internalName}),value, ${vdim} );');
								} else if (isArray) {
									add('\t// this is probably unwise. Need to know how to properly deallocate this memory');
									add('\tif (_unref(_this)->${internalName} != nullptr) delete _unref(_this)->${internalName};');
									add('\t_unref(_this)->${internalName} = new ${makeTypeDecl({t : at, attr: []})}[ value->size ];');
									add('\t_idc_copy_array(_unref(_this)->${internalName}, value);');
									add('\t_unref(_this)->${al} = (value->size);');
								} else if (isPointer) {
									add('\t_unref(_this)->${internalName} = (${makeTypeDecl({t : pt, attr: []})}*)(value);');
								} else if (setter != null)
									add('\t_unref(_this)->${internalName} = ${setter}(${isVal ? "*" : ""}${isRef ? "_unref" : ""}(value));');
								else if (enumName != null)
									add('\t_unref(_this)->${internalName} = (${enumName})HL_NAME(${enumName}_indexToValue0)(value);');
								else
									add('\t_unref(_this)->${internalName} = ${isVal ? "*" : ""}${isRef ? "_unref" : ""}(value);');
								add('\treturn value;');
								add('}');

								if (isVector) {
									// Add componentwise setter

									var vparams = [for (c in 0...vdim) ' ${makeTypeDecl(vta)} value${c}'].join(',');
									add('HL_PRIM void HL_NAME(${name}_set${f.name}${vdim})( ${typeNames.get(name).full} _this, ${vparams} ) {');
									add('\t ${makeTypeDecl(vta)} *p = ${(getter == null) ? "" : getter}(_unref(_this)->${internalName});');

									var vcopy = [for (c in 0...vdim) 'p[$c] = value${c};'].join(' ');
									add('\t${vcopy}');
									add('}');
									var vprim = [for (c in 0...vdim) '${defType(vta)}'].join(' ');
									add('DEFINE_PRIM(_VOID,${name}_set${f.name}${vdim},_IDL ${vprim} );');
								}

								add('DEFINE_PRIM(${defType(t)},${name}_set_${f.name},_IDL ${defType(t)});');
								add('');
							}

						case DConst(_, _, _):
					}
			}
			case DTypeDef(name, attrs, type):
			case DEnum(_), DImplements(_):
		}
	}
	add("}"); // extern C
	sys.io.File.saveContent(opts.outputDir + opts.nativeLib + ".cpp", output.toString());
}

static function command(cmd, args:Array<String>) {
	Sys.println("> " + cmd + " " + args.join(" "));
	var ret = Sys.command(cmd, args);
	if (ret != 0)
		throw "Command '" + cmd + "' has exit with error code " + ret;
}

public static function generateJs(opts:Options, sources:Array<String>, ?params:Array<String>) {
	if (params == null)
		params = [];

	initOpts(opts);

	var hasOpt = false;
	for (p in params)
		if (p.substr(0, 2) == "-O")
			hasOpt = true;
	if (!hasOpt)
		params.push("-O2");

	var lib = opts.nativeLib;

	var emSdk = Sys.getEnv("EMSCRIPTEN");
	if (emSdk == null)
		throw "Missing EMSCRIPTEN environment variable. Install emscripten";
	var emcc = emSdk + "/emcc";

	// build sources BC files
	var outFiles = [];
	sources.push(lib + ".cpp");
	for (cfile in sources) {
		var out = opts.outputDir + cfile.substr(0, -4) + ".bc";
		var args = params.concat(["-c", cfile, "-o", out]);
		command(emcc, args);
		outFiles.push(out);
	}

	// link : because too many files, generate Makefile
	var tmp = opts.outputDir + "Makefile.tmp";
	var args = params.concat([
		"-s",
		'EXPORT_NAME="\'$lib\'"',
		"-s",
		"MODULARIZE=1",
		"--memory-init-file",
		"0",
		"-o",
		'$lib.js'
	]);
	var output = "SOURCES = " + outFiles.join(" ") + "\n";
	output += "all:\n";
	output += "\t" + emcc + " $(SOURCES) " + args.join(" ");
	sys.io.File.saveContent(tmp, output);
	command("make", ["-f", tmp]);
	sys.FileSystem.deleteFile(tmp);
}
}
