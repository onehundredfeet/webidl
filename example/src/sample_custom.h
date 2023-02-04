#ifndef __SAMPLE_CUSTOM_H__
#define __SAMPLE_CUSTOM_H__
#pragma once

class SampleA {
   public:
    float a;
    SampleA() {}
    ~SampleA() {}
};

struct SampleBStruct {
    double b;
};

void SampleBStruct_print(SampleBStruct *obj) {
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