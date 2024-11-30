#ifndef __SAMPLE_CUSTOM_H__
#define __SAMPLE_CUSTOM_H__
#pragma once
#include <stdio.h>

enum SampleEnum {
	SE_0,
	SE_1,
	SE_2
};


class SampleA {
   public:
    float a;
    SampleEnum et;
    SampleA() {
        a = 3.14;
    }
    ~SampleA() {}
    void print() {
        printf("This is class A!\n");
    }
    
    SampleEnum getEnum(SampleEnum p) {
        return static_cast<SampleEnum>((p + 1) % 3);
    }

};

struct SampleBStruct {
    double b;
};

inline void SampleBStruct_print(SampleBStruct *obj) {
    printf("SampleBStruct_print: %p\n", obj);
}

class Sample {
   public:
    Sample() {
        x = 5;
        y = 10;
    }
    ~Sample() {
    }
    Sample(int a, int b) {
        this->x = a;
        this->y = b;
    }
    int x;
    int y;

    int funci(int a) {
        return x + a;
    }
    void print() {
        printf("My pointer is %p, my values are %d and %d\n", this, x, y);
    }
    SampleA *makeA() {
        printf("makeA\n");
        return new SampleA();
    }
    SampleBStruct *makeB() {
        printf("makeA\n");
        return new SampleBStruct();
    }

    Sample *operator+(const Sample &p) {
        return new Sample(this->x + p.x, this->y + p.y);
    }
    void gatherPtr(float *array, int num) {

    }
	void gatherArray(float *array, int num) {
        
    }

    static void testStatic() {
        printf("This is a static method!\n");
    }

    double length() {
        return x * y;
    }
};

#endif