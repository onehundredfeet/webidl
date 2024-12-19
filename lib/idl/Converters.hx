package idl;

#if hl

#elseif cpp

class ArrayConverters {
    @:generic
    public inline static function ptr<T>( a:Array<T> ) : cpp.Pointer<T> {
       //return cpp.NativeArray.address(a, 0);
       return cpp.Pointer.arrayElem(a, 0);
    }
}

#end