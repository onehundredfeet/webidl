package sample;

public class Sample {
    public static void main(String[] args) {
        System.out.println("Hello World!");
    }

    @Override
    public native void finalize();
    private native static void staticVoidFunc();
    private native void voidFunc();
    private native void voidFuncl( long x, char c, boolean b, byte by, short s, int i, float f, double d, String str);
    private native void voidFuncp( Sample s );
    private native int intFunc();
    private native int intFunci(int x);
    private native float floatFuncf(float x);
    private native double doubleFuncd(double x);
    private native double doubleFuncdd(double x, double y);
    private static native String stringFunc();

}
