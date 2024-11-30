package idl;

#if hl
abstract Ref(hl.Bytes) {}
abstract Any(hl.Bytes) {}
abstract VoidPtr(hl.Bytes) from hl.Bytes {}
abstract NativePtr<T>(hl.BytesAccess<T>) {}
#else
abstract Ref(Dynamic) {}
abstract Any(Dynamic) {}
abstract VoidPtr(Dynamic) {}
abstract NativePtr<T>(Dynamic) {}
#end
