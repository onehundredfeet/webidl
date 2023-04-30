```c++

JNIEXPORT void JNICALL Java_sample_SampleNative_fn_1nativeArrayF
  (JNIEnv *env, jobject obj, jfloatArray array) {
    //access
    float* raw = env->GetFloatArrayElements(array, nullptr);
    // Do all my processing
    ...
    //release
    env->ReleaseFloatArrayElements(array, raw, 0);
  }

JNIEXPORT void JNICALL Java_sample_SampleNative_fn_1ArrayF
  (JNIEnv *env, jobject obj, jobject array) {
    //preamble - could be cached
    	jclass haxe_array_class = p->FindClass("haxe/root/Array");
      jmethod array_get = p->GetMethodID(haxe_array_class, "__get", "(I)Ljava/lang/Object;");
      jclass float_class = p->FindClass("java/lang/Float");
      jmethod float_get = p->GetMethodID(float_class, "floatValue", "()F");

      // get length
      ...
      ///
      float *temp = new float[length];
      for (auto i = 0; i < length; ++i) {
        jobject tmpObj = (*env)->CallObjectMethod(array, array_get, i);
        temp[i] = (*env)->CallFloatMethod(tmpObj, float_get );
      }

      // do all my processing
      ...
  }


  ```