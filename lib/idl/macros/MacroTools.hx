package idl.macros;

import haxe.macro.Expr;
import haxe.macro.Context;

// borrowed from tink_macro
// The MIT License (MIT)
// Copyright (c) 2013 Juraj Kirchheim
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
class MacroTools {
	static public function asTypePath(s:String, ?params):TypePath {
		var parts = s.split('.');
		var name = parts.pop(), sub = null;
		if (parts.length > 0 && parts[parts.length - 1].charCodeAt(0) < 0x5B) {
			sub = name;
			name = parts.pop();
			if (sub == name)
				sub = null;
		}
		return {
			name: name,
			pack: parts,
			params: params == null ? [] : params,
			sub: sub
		};
	}

	static public inline function asComplexType(s:String, ?params)
		return TPath(asTypePath(s, params));

	static public inline function sanitize(pos:Position)
		return if (pos == null) Context.currentPos(); else pos;

	static public inline function asConstExpr(s:String, ?p : Position) : Expr {
    return {expr: EConst(CString(s)), pos: p}
  }

  static public inline function asFieldAccess(s:String, ?p : Position) : Expr {
    var parts = s.split(".");
    if (parts.length == 0) {
      throw "Invalid field access";
    }
    var e = EConst(CIdent(parts.shift()));
    for (part in parts) {
      e = EField({expr: e, pos: p}, part);
    }
    return {expr: e, pos: p};
  }
	static public inline function at(e:ExprDef, ?pos:Position)
		return {
			expr: e,
			pos: sanitize(pos)
		};
}
