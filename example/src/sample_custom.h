#ifndef __SAMPLE_CUSTOM_H__
#define __SAMPLE_CUSTOM_H__
#pragma once
#include <stdio.h>

class SampleA {
   public:
    float a;
    SampleA() {}
    ~SampleA() {}
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
    }
    ~Sample() {
    }
    Sample(long long a, long long b) {
        this->x = a;
        this->y = b;
    }
    long long x;
    long long y;

    int func_i(int x) {
        return x;
    }
    SampleA *makeA() {
        return new SampleA();
    }
    SampleBStruct *makeB() {
        return new SampleBStruct();
    }

    Sample *operator+(const Sample &p) {
        return new Sample(this->x + p.x, this->y + p.y);
    }
    double length() {
        return x * y;
    }
};

#endif