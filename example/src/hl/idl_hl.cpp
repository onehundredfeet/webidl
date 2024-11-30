#ifdef EMSCRIPTEN

#include <emscripten.h>
#define HL_PRIM
#define HL_NAME(n)	EMSCRIPTEN_KEEPALIVE eb_##n
#define DEFINE_PRIM(ret, name, args)
#define _OPT(t) t*
#define _GET_OPT(value,t) *value
#define alloc_ref(r, _) r
#define alloc_ref_const(r,_) r
#define _ref(t)			t
#define _unref(v)		v
#define free_ref(v) delete (v)
#define HL_CONST const

#else

#define HL_NAME(x) sample_##x
#include <hl.h>
#include "hl-idl-helpers.hpp"
// Need to link in helpers
//HL_API hl_type hltx_ui16;
//HL_API hl_type hltx_ui8;
HL_PRIM hl_type hltx_ui16 = { HUI16 };
HL_PRIM hl_type hltx_ui8 = { HUI8 };

#define _IDL _BYTES
#define _OPT(t) vdynamic *
#define _GET_OPT(value,t) (value)->v.t

static  hl_type *strType = nullptr;
void hl_cache_string_type( vstring *str) {
   strType = str->t;
}

vstring * hl_utf8_to_hlstr( const char *str) {
    int strLen = (int)strlen( str );
    uchar * ubuf = (uchar*)hl_gc_alloc_noptr((strLen + 1) << 1);
    hl_from_utf8( ubuf, strLen, str );

    vstring* vstr = (vstring *)hl_gc_alloc_raw(sizeof(vstring));

    vstr->bytes = ubuf;
    vstr->length = strLen;
    vstr->t = strType;
    return vstr;
}
vstring * hl_utf8_to_hlstr( const std::string &str) {
	return hl_utf8_to_hlstr(str.c_str());
}

HL_PRIM vstring * HL_NAME(getdllversion)(vstring * haxeversion) {
	strType = haxeversion->t;
	return haxeversion;
}
DEFINE_PRIM(_STRING, getdllversion, _STRING);

class HNativeBuffer {
    unsigned char *_ptr;
    int _size;

   public:
   inline unsigned char * ptr() { return _ptr; }
   inline int size() { return _size; }
   HNativeBuffer(unsigned char *ptr, int size) : _ptr(ptr), _size(size) {}
   HNativeBuffer(int size) : _ptr(new unsigned char[size]), _size(size) {}
    ~HNativeBuffer() {
        if (_ptr != nullptr)
            delete [] _ptr;
    }
};

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
template <typename T> struct pref {
	void (*finalize)( pref<T> * );
	T *value;
};

#define _ref(t) pref<t>
#define _unref(v) v->value
#define _unref_ptr_safe(v) (v != nullptr ? v->value : nullptr)
#define alloc_ref(r,t) _alloc_ref(r,finalize_##t)
#define alloc_ref_const(r, _) _alloc_const(r)
#define HL_CONST

template<typename T> void free_ref( pref<T> *r ) {
	if( !r->finalize ) hl_error("delete() is not allowed on const value.");
	delete r->value;
	r->value = NULL;
	r->finalize = NULL;
}

template<typename T> void free_ref( pref<T> *r, void (*deleteFunc)(T*) ) {
	if( !r->finalize ) hl_error("delete() is not allowed on const value.");
	deleteFunc( r->value );
	r->value = NULL;
	r->finalize = NULL;
}

inline void testvector(_h_float3 *v) {
  printf("v: %f %f %f\n", v->x, v->y, v->z);
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


inline static varray* _idc_alloc_array(unsigned char *src, int count) {
	if (src == nullptr) return nullptr;

	varray *a = NULL;
	float *p;
	a = hl_alloc_array(&hltx_ui8, count);
	p = hl_aptr(a, float);

	for (int i = 0; i < count; i++) {
		p[i] = src[i];
	}
	return a;
}

inline static varray* _idc_alloc_array( char *src, int count) {
	return _idc_alloc_array((unsigned char *)src, count);
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

#endif

#ifdef _WIN32
#pragma warning(disable:4305)
#pragma warning(disable:4244)
#pragma warning(disable:4316)
#endif

#include "sample_custom.h"





extern "C" {

static SampleEnum SampleEnum__values[] = { SE_0,SE_1,SE_2 };
HL_PRIM int HL_NAME(SampleEnum_toValue0)( int idx ) {
	return (int)SampleEnum__values[idx];
}
DEFINE_PRIM(_I32, SampleEnum_toValue0, _I32);
HL_PRIM int HL_NAME(SampleEnum_indexToValue1)( int idx ) {
	return (int)SampleEnum__values[idx];
}
DEFINE_PRIM(_I32, SampleEnum_indexToValue1, _I32);
HL_PRIM int HL_NAME(SampleEnum_valueToIndex1)( int value ) {
	for( int i = 0; i < 3; i++ ) if ( value == (int)SampleEnum__values[i]) return i; return -1;
}
DEFINE_PRIM(_I32, SampleEnum_valueToIndex1, _I32);
HL_PRIM int HL_NAME(SampleEnum_fromValue1)( int value ) {
	for( int i = 0; i < 3; i++ ) if ( value == (int)SampleEnum__values[i]) return i; return -1;
}
DEFINE_PRIM(_I32, SampleEnum_fromValue1, _I32);
HL_PRIM int HL_NAME(SampleEnum_fromIndex1)( int index ) {return index;}
DEFINE_PRIM(_I32, SampleEnum_fromIndex1, _I32);
static void finalize_SampleA( pref<SampleA>* _this ) { free_ref(_this ); }
HL_PRIM void HL_NAME(SampleA_delete)( pref<SampleA>* _this ) {
	free_ref(_this );
}
DEFINE_PRIM(_VOID, SampleA_delete, _IDL);
static void finalize_SampleB( pref<SampleBStruct>* _this ) { free_ref(_this ); }
HL_PRIM void HL_NAME(SampleB_delete)( pref<SampleBStruct>* _this ) {
	free_ref(_this );
}
DEFINE_PRIM(_VOID, SampleB_delete, _IDL);
static void finalize_Sample( pref<Sample>* _this ) { free_ref(_this ); }
HL_PRIM void HL_NAME(Sample_delete)( pref<Sample>* _this ) {
	free_ref(_this );
}
DEFINE_PRIM(_VOID, Sample_delete, _IDL);
HL_PRIM float HL_NAME(SampleA_get_a)( pref<SampleA>* _this ) {
	return _unref(_this)->a;
}
DEFINE_PRIM(_F32,SampleA_get_a,_IDL);
HL_PRIM float HL_NAME(SampleA_set_a)( pref<SampleA>* _this, float value ) {
	_unref(_this)->a = (value);
	return value;
}
DEFINE_PRIM(_F32,SampleA_set_a,_IDL _F32);

HL_PRIM int HL_NAME(SampleA_get_et)( pref<SampleA>* _this ) {
	return HL_NAME(SampleEnum_valueToIndex1)(_unref(_this)->et);
}
DEFINE_PRIM(_I32,SampleA_get_et,_IDL);
HL_PRIM int HL_NAME(SampleA_set_et)( pref<SampleA>* _this, int value ) {
	_unref(_this)->et = (SampleEnum)HL_NAME(SampleEnum_indexToValue1)(value);
	return value;
}
DEFINE_PRIM(_I32,SampleA_set_et,_IDL _I32);

HL_PRIM pref<SampleA>* HL_NAME(SampleA_new0)() {
	printf("Allocating SampleA\n");
	return alloc_ref((new SampleA()),SampleA);
}
DEFINE_PRIM(_IDL, SampleA_new0,);

HL_PRIM void HL_NAME(SampleA_print0)(pref<SampleA>* _this) {
	(_unref(_this)->print());
}
DEFINE_PRIM(_VOID, SampleA_print0, _IDL);

HL_PRIM int HL_NAME(SampleA_getEnum1)(pref<SampleA>* _this, int p) {
	return HL_NAME(SampleEnum_valueToIndex1)(_unref(_this)->getEnum(SampleEnum__values[p]));
}
DEFINE_PRIM(_I32, SampleA_getEnum1, _IDL _I32);

HL_PRIM double HL_NAME(SampleB_get_b)( pref<SampleBStruct>* _this ) {
	return _unref(_this)->b;
}
DEFINE_PRIM(_F64,SampleB_get_b,_IDL);
HL_PRIM double HL_NAME(SampleB_set_b)( pref<SampleBStruct>* _this, double value ) {
	_unref(_this)->b = (value);
	return value;
}
DEFINE_PRIM(_F64,SampleB_set_b,_IDL _F64);

HL_PRIM void HL_NAME(SampleB_print0)(pref<SampleBStruct>* _this) {
	(SampleBStruct_print( _unref(_this) ));
}
DEFINE_PRIM(_VOID, SampleB_print0, _IDL);

HL_PRIM int HL_NAME(Sample_get_x)( pref<Sample>* _this ) {
	return _unref(_this)->x;
}
DEFINE_PRIM(_I32,Sample_get_x,_IDL);
HL_PRIM int HL_NAME(Sample_set_x)( pref<Sample>* _this, int value ) {
	_unref(_this)->x = (value);
	return value;
}
DEFINE_PRIM(_I32,Sample_set_x,_IDL _I32);

HL_PRIM int HL_NAME(Sample_get_y)( pref<Sample>* _this ) {
	return _unref(_this)->y;
}
DEFINE_PRIM(_I32,Sample_get_y,_IDL);
HL_PRIM int HL_NAME(Sample_set_y)( pref<Sample>* _this, int value ) {
	_unref(_this)->y = (value);
	return value;
}
DEFINE_PRIM(_I32,Sample_set_y,_IDL _I32);

HL_PRIM pref<Sample>* HL_NAME(Sample_new0)() {
	printf("WTF\n");
	fflush(stdout);
	return alloc_ref((new Sample()),Sample);
}
DEFINE_PRIM(_IDL, Sample_new0,);

HL_PRIM int HL_NAME(Sample_funci1)(pref<Sample>* _this, int x) {
	return (_unref(_this)->funci(x));
}
DEFINE_PRIM(_I32, Sample_funci1, _IDL _I32);

HL_PRIM void HL_NAME(Sample_print0)(pref<Sample>* _this) {
	(_unref(_this)->print());
}
DEFINE_PRIM(_VOID, Sample_print0, _IDL);

HL_PRIM pref<SampleA>* HL_NAME(Sample_makeA0)(pref<Sample>* _this) {
	printf("makeA outside %p\n", _this);
	return alloc_ref((_unref(_this)->makeA()),SampleA);
}
DEFINE_PRIM(_IDL, Sample_makeA0, _IDL);

HL_PRIM void HL_NAME(Sample_gatherPtr2)(pref<Sample>* _this, vbyte* array, int num) {
	(_unref(_this)->gatherPtr((float*)array, num));
}
DEFINE_PRIM(_VOID, Sample_gatherPtr2, _IDL _BYTES _I32);

HL_PRIM void HL_NAME(Sample_gatherArray2)(pref<Sample>* _this, varray* array, int num) {
	(_unref(_this)->gatherArray(hl_aptr(array,float), num));
}
DEFINE_PRIM(_VOID, Sample_gatherArray2, _IDL _ARR _I32);

HL_PRIM double HL_NAME(Sample_length0)(pref<Sample>* _this) {
	return (_unref(_this)->length());
}
DEFINE_PRIM(_F64, Sample_length0, _IDL);

}
