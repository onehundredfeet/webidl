package idl;

abstract Ref(#if hl hl.Bytes #else Dynamic #end) {
}

abstract Any(#if hl hl.Bytes #else Dynamic #end) {
}

abstract VoidPtr(#if hl hl.Bytes #else Dynamic #end) #if hl from hl.Bytes #end{
}

abstract NativePtr<T>(#if hl hl.BytesAccess<T> #else Dynamic #end) {
}
