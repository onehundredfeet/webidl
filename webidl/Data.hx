package webidl;

typedef Data = Array<Definition>;

enum Definition {
	DInterface( name : String, attrs : Array<Attrib>, fields : Array<Field> );
	DImplements( type : String, interfaceName : String );
	DEnum( name : String, values : Array<String> );
}

typedef Field = {
	var name : String;
	var kind : FieldKind;
}

enum FieldKind {
	FMethod( args : Array<FArg>, ret : TypeAttr );
	FAttribute( t : TypeAttr );
}

typedef FArg = { name : String, opt : Bool, t : TypeAttr };
typedef TypeAttr = { var t : Type; var attr : Array<Attrib>; };

enum Type {
	TVoid;
	TInt;
	TShort;
	TFloat;
	TDouble;
	TBool;
	TAny;
	TVoidPtr;
	TCustom( id : String );
	TArray( t : Type );
}

enum Attrib {
	// fields
	AValue;
	ARef;
	AConst;
	AOperator( op : String );
	// interfaces
	ANoDelete;
	APrefix( prefix : String );
	AJSImplementation( name : String );
}
