package idl;

import haxe.macro.Printer;
import idl.Data;
import haxe.macro.Expr;

using StringTools;
using idl.macros.MacroTools;



class GenerateHaxe {
	var pack:Array<String>;
	var opts:Options;
    final nullPosition : haxe.macro.Expr.Position = { min : 0, max : 0, file : 'null' };
	var p:haxe.macro.Expr.Position = {min: 0, max: 0, file: 'null'};
	var types:Array<TypeDefinition> = [];
	var typeNames = new Map<String, haxe.macro.TypePath>();
    var _printer = new Printer();
    var _inline = true;
    var _targets:Array<HaxeGenerationTarget>;
    var _currentTarget:HaxeGenerationTarget;

    public function new(opts:Options, targets:Array<HaxeGenerationTarget> = null) {
		this.pack = opts.packageName.split(".");
		this.opts = opts;
        _targets = targets != null ? targets : [new HaxeGenerationTargetHL(opts,typeNames)];
	}

	dynamic function error(msg:String, p:haxe.macro.Expr.Position) {
		#if macro
		Context.error(msg, p);
		#else
		if (p != null)
			trace('${p}:' + msg);
		else
			trace(msg);
		#end
	}

    dynamic function currentPosition() :haxe.macro.Expr.Position{
        #if macro
        return Context.currentPos();
        #else
        return nullPosition;
        #end
    }
    
    dynamic function warning(msg:String, p:haxe.macro.Expr.Position) {
        #if macro
        Context.warning(msg, p);
        #else
        if (p != null)
			trace('${p}:' + msg);
		else
			trace(msg);
        #end
    }

        
	public function buildTypes(opts:Options):Array<TypeDefinition> {
		var declarations = loadIDLDeclarations();

		for (d in declarations) {
            buildDecl(d);
		}

		return types;
	}

    function makeMacroPosition( pos : idl.Data.Position ) : haxe.macro.Expr.Position{
		if( pos == null )
			return nullPosition;
		return makePosition({ min : pos.pos, max : pos.pos + 1, file : pos.file });
	}

    function makePosition(p:{min:Int, max:Int, file:String}):haxe.macro.Expr.Position {
		#if macro
		return Context.makePosition(p);
		#else
		return p;
		#end
	}

    function defVal( t : TypeAttr ) : Expr {
		return switch( t.t ) {
		case TVoid: throw "assert";
		case TInt, TUInt, TShort, TInt64, TChar: { expr : EConst(CInt("0")), pos : p };
		case TFloat, TDouble: { expr : EConst(CFloat("0.")), pos : p };
		case TBool: { expr : EConst(CIdent("false")), pos : p };
		case TEnum(name): ECall(EField(EConst(CIdent(name)).at(p),"fromIndex").at(p), [EConst(CInt("0")).at(p)] ).at(p); //{ expr : , pos : p };
		case TCustom(id):
			var ex = { expr : EConst(CInt("0")), pos : p };
			var tp = TPath({ pack : [], name : id });

			if (typeNames.exists(id))  
				{ expr : ECast(ex, tp), pos : p };
			else 
				{ expr : EConst(CIdent("null")), pos : p };
		default: 
			{ expr : EConst(CIdent("null")), pos : p };
		}
	}

    function makeNativeFieldRaw( iname : String, fname : String, pos : Position, args : Array<FArg>, ret : TypeAttr, pub : Bool ) : Field {
		var name = fname;
		var isConstr = name == iname || fname == "new";
		if( isConstr ) {
			name = "new";
			ret = { t : TCustom(iname), attr : [] };
		}

		var expr = if( ret.t == TVoid )
			{ expr : EBlock([]), pos : p };
		else
			{ expr : EReturn(defVal(ret)), pos : p };

		var access : Array<Access> = [];
		if( _inline ) access.push(AInline);
		if( pub ) access.push(APublic);
		if( isConstr ) access.push(AStatic);
		if (ret.attr.contains(AStatic)) {
			access.push(AStatic);
		}

		var x =
		 {
			pos : pos,
			name : pub ? name : name + args.length,
			meta : [_currentTarget.makeNative(iname+"_" + name + (name == "delete" ? "" : ""+args.length),p)],
			access : access,
			kind : FFun({
				ret : _currentTarget.makeType(ret, true),
				expr : expr,
				args : [for( a in args ) {

					//This pattern is brutallly bad There must be a cleaner way to do this
					var sub = false;
					for(aattr in a.t.attr) {
						switch(aattr) {
								case ASubstitute(_): 
								sub = true;
								break;
							default: 
						}
					}
					if (a.t.attr.contains(AReturn) || sub) {continue;}
					{ name : a.name, opt : a.opt, type : _currentTarget.makeType(a.t, false) }}],
			}),
		};

		
		return x;
	}

	function makeNativeField( iname : String, hname : String, f : idl.Data.Field, args : Array<FArg>, ret : TypeAttr, pub : Bool ) : Field {
		return makeNativeFieldRaw(iname, hname, makeMacroPosition(f.pos), args, ret, pub);
	}

	function filterArgs( args : Array<FArg>) {
		var b : Array<FArg> = [];

		for(a in args) {
			var skip = false;
			for (at in a.t.attr) {
				switch(at) {
					case AVirtual: skip = true;
					default:
				}
			}
			if (!skip) 
				b.push(a);
		}
		return b;
	}

    function makeEither( arr : Array<ComplexType> ) {
		var i = 0;
		var t = arr[i++];
		while( i < arr.length ) {
			var t2 = arr[i++];
			t = TPath({ pack : ["haxe", "extern"], name : "EitherType", params : [TPType(t), TPType(t2)] });
		}
		return t;
	}

    function getElementType(t:TypeAttr) {
        return switch (t.t) {
            case TPointer(at), TArray(at, _):{t: at, attr: t.attr};
            default: throw "Not an array type: " + t.t.getName() + " : " + t.t.getParameters();
        }
    }
    
    function makeElementType(t:idl.Data.TypeAttr, isReturn = false) {
        return switch (t.t) {
            case TPointer(at), TArray(at, _): _currentTarget.makeType({t: at, attr: t.attr}, isReturn);
            default: throw "Not an array type: " + t.t.getName() + " : " + t.t.getParameters();
        }
    }

	function buildDecl(d:Definition) {
		var p = makeMacroPosition(d.pos);
		switch (d.kind) {
			case DInterface(iname, attrs, fields):
				var dfields:Array<Field> = [];
				var forceCamel = attrs.indexOf(AForceCamelCase) >= 0;

				var variants = new Map();
				function getVariants(name:String) {
					if (variants.exists(name))
						return null;
					variants.set(name, true);
					var fl = [];
					for (f in fields)
						if (f.name == name)
							switch (f.kind) {
								case FMethod(args, ret):
									fl.push({args: filterArgs(args), ret: ret, pos: f.pos});
								default:
							}
					return fl;
				}

				for (f in fields) {
					var haxeName = forceCamel ? f.name.substr(0, 1).toLowerCase() + f.name.substr(1) : f.name;

					switch (f.kind) {
						case FMethod(_):
							var vars = getVariants(f.name);
							if (vars == null)
								continue;

							var isConstr = f.name == iname || f.name == "new";
							if (isConstr) {
								haxeName = "new";
							}
							if (vars.length == 1 && !isConstr) {
								var f = makeNativeField(iname, haxeName, f, vars[0].args, vars[0].ret, true);
								dfields.push(f);
							} else {
								// create dispatching code
								var maxArgs = 0;
								for (v in vars)
									if (v.args.length > maxArgs)
										maxArgs = v.args.length;

								if (vars.length > 1 && maxArgs == 0)
									error("Duplicate method declaration", makeMacroPosition(vars.pop().pos));

								var targs:Array<FunctionArg> = [];
								var argsTypes = [];
								for (i in 0...maxArgs) {
									var types:Array<{t:TypeAttr, sign:String}> = [];
									var names = [];
									var opt = false;
									for (v in vars) {
										var a = v.args[i];
										if (a == null) {
											opt = true;
											continue;
										}
										var sign = haxe.Serializer.run(a.t);
										var found = false;
										for (t in types)
											if (t.sign == sign) {
												found = true;
												break;
											}
										if (!found)
											types.push({t: a.t, sign: sign});
										if (names.indexOf(a.name) < 0)
											names.push(a.name);
										if (a.opt)
											opt = true;
									}
									argsTypes.push(types);
									targs.push({
										name: names.join("_"),
										opt: opt,
										type: makeEither([for (t in types) _currentTarget.makeType(t.t, false)]),
									});
								}

								// native impls
								var retTypes:Array<{t:TypeAttr, sign:String}> = [];
								for (v in vars) {
									var f = makeNativeField(iname, haxeName, f, v.args, v.ret, false);

									var sign = haxe.Serializer.run(v.ret);
									var found = false;
									for (t in retTypes)
										if (t.sign == sign) {
											found = true;
											break;
										}
									if (!found)
										retTypes.push({t: v.ret, sign: sign});

									dfields.push(f);
								}

								vars.sort(function(v1, v2) return v1.args.length - v2.args.length);

								// dispatch only on args count
								function makeCall(v:{args:Array<FArg>, ret:TypeAttr}):Expr {
									var ident = {expr: EConst(CIdent((haxeName) + v.args.length)), pos: p};
									var e:Expr = {expr: ECall(ident, [
										for (i in 0...v.args.length) {expr: ECast({expr: EConst(CIdent(targs[i].name)), pos: p}, null), pos: p}
									]), pos: p};
									if (v.ret.t != TVoid)
										e = {expr: EReturn(e), pos: p};
									else if (isConstr)
										e = macro this = $e;
									return e;
								}

								var expr = makeCall(vars[vars.length - 1]);
								for (i in 1...vars.length) {
									var v = vars[vars.length - 1 - i];
									var aname = targs[v.args.length].name;
									var call = makeCall(v);
									expr = macro if ($i{aname} == null) $call else $expr;
								}

								dfields.push({
									name: haxeName,
									pos: makeMacroPosition(f.pos),
									access: [APublic, AInline],
									kind: FFun({
										expr: expr,
										args: targs,
										ret: makeEither([for (t in retTypes) _currentTarget.makeType(t.t, false)]),
									}),
								});
							}

						case FAttribute(t):
							switch (t.t) {
								case TArray(at, sizeField):
									var et = getElementType(t);
									var cetr = _currentTarget.makeType(et, true);
									var cet = _currentTarget.makeType(et, false);

									dfields.push({
										pos: p,
										name: "get" + haxeName,
										meta: [_currentTarget.makeNative(iname + "_get_" + haxeName, p)],
										kind: FFun({
											ret: cetr,
											expr: macro return ${defVal(et)},
											args: [{name: "index", type: macro :Int}],
										}),
										access: [APublic]
									});
									dfields.push({
										pos: p,
										name: "set" + haxeName,
										meta: [_currentTarget.makeNative(iname + "_set_" + haxeName, p)],
										kind: FFun({
											ret: cetr,
											expr: macro return ${defVal(et)},
											args: [{name: "index", type: macro :Int}, {name: "_v", type: cet}],
										}),
										access: [APublic]
									});

								default:
									var hasSet = t.attr == null || t.attr.indexOf(AReadOnly) < 0;
									var tt = _currentTarget.makeType(t, false);

									var fkind = hasSet ? FProp("get", "set", tt) : FProp("get", "never", tt);
									dfields.push({
										pos: p,
										name: haxeName,
										kind: fkind,
										access: [APublic],
									});
									dfields.push({
										pos: p,
										name: "get_" + haxeName,
										meta: [_currentTarget.makeNative(iname + "_get_" + haxeName, p)],
										kind: FFun({
											ret: _currentTarget.makeType(t, true),
											expr: macro return ${defVal(t)},
											args: [],
										}),
									});
									if (hasSet) {
										dfields.push({
											pos: p,
											name: "set_" + haxeName,
											meta: [_currentTarget.makeNative(iname + "_set_" + haxeName, p)],
											kind: FFun({
												ret: tt,
												expr: macro return ${defVal(t)},
												args: [{name: "_v", type: tt}],
											}),
										});
									}
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

									if (isVector && false) {
										dfields.push({
											pos: p,
											name: "set" + haxeName + vdim,
											meta: [_currentTarget.makeNative(iname + "_set" + haxeName + vdim, p)],
											access: [APublic, AInline],
											kind: FFun({
												ret: macro :Void,
												expr: macro return,
												args: [for (c in 0...vdim) {name: "_v" + c, type: _currentTarget.makeType(vta, false)}],
											}),
										});
									}
							}

						case DConst(name, type, value):
							var num = Std.parseInt(value);
							var vmac = num != null ? {expr: EConst(CInt(value)), pos: currentPosition()} : macro $i{value};

							dfields.push({
								pos: p,
								name: name,
								access: [APublic, AStatic, AInline],
								kind: FVar(_currentTarget.makeType({t: type, attr: []}, false), vmac)
							});
					}
				}
				var td:TypeDefinition = {
					pos: p,
					pack: pack,
					name: makeName(iname),
					meta: [],
					kind: TDAbstract(macro :idl.Types.Ref, [], [macro :idl.Types.Ref], [macro :idl.Types.Ref]),
					fields: dfields,
				};

				if (attrs.indexOf(ANoDelete) < 0) {
					dfields.push(makeNativeField(iname, "delete", {name: "delete", pos: null, kind: null}, [], {t: TVoid, attr: []}, true));
				}

				// if (!hl) {
				// 	for (f in dfields)
				// 		if (f.meta != null)
				// 			for (m in f.meta)
				// 				if (m.name == ":hlNative") {
				// 					if (f.access == null)
				// 						f.access = [];
				// 					switch (f.kind) {
				// 						case FFun(df):
				// 							var call = opts.nativeLib + "._eb_" + switch (m.params[1].expr) {
				// 								case EConst(CString(name)): name;
				// 								default: throw "!";
				// 							};
				// 							var args:Array<Expr> = [for (a in df.args) {expr: EConst(CIdent(a.name)), pos: p}];
				// 							if (f.access.contains(AStatic)) {
				// 								args.unshift(macro this);
				// 							}
				// 							df.expr = macro return untyped $i{call}($a{args});
				// 						default: throw "assert";
				// 					}
				// 					if (f.access.indexOf(AInline) == -1)
				// 						f.access.push(AInline);
				// 					f.meta.remove(m);
				// 					break;
				// 				}
				// }

				types.push(td);
			case DImplements(name, intf):
				var name = makeName(name);
				var intf = makeName(intf);
				var found = false;
				for (t in types)
					if (t.name == name) {
						found = true;
						switch (t.kind) {
							case TDAbstract(a, _):
								t.fields.push({
									pos: p,
									name: "_to" + intf,
									meta: [{name: ":to", pos: p}],
									access: [AInline],
									kind: FFun({
										args: [],
										expr: macro return cast this,
										ret: TPath({pack: [], name: intf}),
									}),
								});

								var toImpl = [intf];
								while (toImpl.length > 0) {
									var intf = toImpl.pop();
									var td = null;
									for (t2 in types) {
										if (t2.name == intf)
											switch (t2.kind) {
												case TDAbstract(a2, _, to):
													for (inheritedField in t2.fields) {
														// Search for existing field
														var fieldExists = false;
														for (existingField in t.fields) {
															if (inheritedField.name == existingField.name) {
																fieldExists = true;
																break;
															}
														}

														if (!fieldExists) {
															t.fields.push(inheritedField);
														}
													}
												default:
											}
									}
								}

							default:
								warning("Cannot have " + name + " extends " + intf, p);
						}
						break;
					}
				if (!found)
					warning("Class " + name + " not found for implements " + intf, p);
			case DEnum(name, attrs, values):
				var index = 0;
				function cleanEnum(v:String):String {
					return v.replace(":", "_");
				}
				var cfields = [
					for (v in values) {pos: p, name: cleanEnum(v), kind: FVar(null, {expr: EConst(CInt("" + (index++))), pos: p})}
				];

				// Add Int Conversion
				var ta:TypeAttr = {t: TInt, attr: [AStatic]};
				var toValue = makeNativeFieldRaw(name, "indexToValue", p, [{name: "index", opt: false, t: {t: TInt, attr: []}}], ta, true);
				cfields.push(toValue);

				ta = {t: TInt, attr: [AStatic]};
				var toIndex = makeNativeFieldRaw(name, "valueToIndex", p, [{name: "value", opt: false, t: {t: TInt, attr: []}}], ta, true);
				cfields.push(toIndex);

				ta = {t: TEnum(name), attr: [AStatic]};
				var fromValue = makeNativeFieldRaw(name, "fromValue", p, [{name: "value", opt: false, t: {t: TInt, attr: []}}], ta, true);
				cfields.push(fromValue);

				ta = {t: TEnum(name), attr: [AStatic]};
				var fromIndex = makeNativeFieldRaw(name, "fromIndex", p, [{name: "index", opt: false, t: {t: TInt, attr: []}}], ta, true);
				cfields.push(fromIndex);

				ta = {t: TInt, attr: []};
				var toValue = makeNativeFieldRaw(name, "toValue", p, [], ta, true);
				cfields.push(toValue);

				var enumT:TypeDefinition = {
					pos: p,
					pack: pack,
					name: makeName(name),
					meta: [],
					kind: TDAbstract(macro :Int, [AbEnum]),
					fields: cfields,
				};

				var enumTP:TypePath = {
					pack: pack,
					name: enumT.name
				};

				typeNames[name] = enumTP;
				types.push(enumT);
			case DTypeDef(name, attrs, type, dtype):
		}
	}



	public function generate() {

        var targetMap = new Map<HaxeGenerationTarget, Array<TypeDefinition>>();
        var multiTypeMap = new Map<String, Map<HaxeGenerationTarget, TypeDefinition>>();
        for (target in _targets) {
            types = [];
            typeNames = new Map<String, haxe.macro.TypePath>();
            _currentTarget = target;
            // implicitly adds them to types
            buildTypes(opts);
            targetMap.set(target, types);

            for (t in types) {
                var name = t.name;
                if (!multiTypeMap.exists(name)) {
                    multiTypeMap.set(name, new Map<HaxeGenerationTarget, TypeDefinition>());
                }
                multiTypeMap.get(name).set(target, t);
            }
        }


        var root = opts.hxDir + opts.packageName.split(".").join("/");
        trace('root ${root}');
        for (mtk in multiTypeMap.keys()) {
            var fname = root + "/" + mtk + ".hx";
            trace('writing ${fname}');
            var builder = new StringBuf();
            builder.add('package ${opts.packageName};\n');
            builder.add('import idl.Types;\n');
            for (target in _targets) {
                var t = multiTypeMap.get(mtk).get(target);
                builder.add(target.getTargetCondition());
                builder.add('\n\n');
                builder.add(_printer.printTypeDefinition(t, false));
                builder.add('\n#end\n');
            }
            sys.io.File.saveContent(fname, builder.toString());
        }
	}

	function makeName(name:String) {
		// name - list of comma separated prefixes
		if (opts.chopPrefix != null) {
			var prefixes = opts.chopPrefix.split(',');
			for (prefix in prefixes) {
				if (StringTools.startsWith(name, prefix)) {
					name = name.substr(prefix.length);
				}
			}
		}
		return capitalize(name);
	}

	function loadIDLDeclarations() {
		// load IDL
		var file = opts.idlFile;
		var content = try {
			sys.io.File.getBytes(file);
		} catch (e:Dynamic) {
			error("" + e, p);
			return null;
		}

		// parse IDL
		var parse = new idl.Parser();
		var decls = null;
		try {
			decls = parse.parseFile(file, new haxe.io.BytesInput(content));
		} catch (msg:String) {
			var lines = content.toString().split("\n");
			var start = lines.slice(0, parse.line - 1).join("\n").length + 1;
			error(msg, makePosition({min: start, max: start + lines[parse.line - 1].length, file: file}));
			return null;
		}

		return decls;
	}

	/**
	 * Capitalize the first letter of a string
	 * @param text The string to capitalize
	 */
	private static function capitalize(text:String) {
		return text.charAt(0).toUpperCase() + text.substring(1);
	}
}
