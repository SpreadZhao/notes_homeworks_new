---
title: oboe实现一按就响
---

```ad-danger
title: 马的
老子的文件崩了一次，都tm没了。这个是重写的版本，没心情写了，比较随意。
```

# 1 再次改造

## 1.1 RegisterNatives迁移

之后我打算所有的native都采用[[Study Log/android_study/ndk/2_simple_timer#4 Additional|2_simple_timer]]这种方式。但是这样写起来比较麻烦，所以统一一下。

```cpp
#define SIZE_OF_METHOD(X) (sizeof(X) / sizeof(JNINativeMethod))

typedef JNINativeMethod Methods[];

static const std::string class_name_simple_timer = "com/spread/nativestudy/fragments/SimpleTimerFragment";
static const Methods methods_simple_timer = {
        {"testRegister", "()V", (void *)(testRegister)}
};

static inline void registerJMethods(JNIEnv *env, std::string className, JNINativeMethod *methods, size_t size) {
    jclass clz = env->FindClass(className.c_str());
    if (clz == nullptr) return;
    env->RegisterNatives(clz, methods, size);
}
```

- [ ] #TODO 这里`methods_simple_timer`不应该是const，否则调用registerJMethods的时候数组名无法转换成指针。为啥？ ⏫

使用方法：

```cpp
registerJMethods(env, class_name_simple_timer, methods_simple_timer,
                     SIZE_OF_METHOD(methods_simple_timer));
```

## 1.2 JNI\_OnLoad迁移

因为`JNI_OnLoad()`只能调用一次，所以不能写在`common.h`里面。我搞了一个main.cpp，专门用来执行那些只会执行一次的逻辑：

```cpp
JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    JNIEnv *env;
    if (vm->GetEnv((void **)&env, JNI_VERSION_1_6) != JNI_OK) {
        return JNI_ERR;
    }
    timerPrepare(vm);
    registerJMethods(env, class_name_simple_timer, methods_simple_timer,
                     SIZE_OF_METHOD(methods_simple_timer));
	// 本章oboe的新方法
    registerJMethods(env, class_name_oboe, methods_oboe, SIZE_OF_METHOD(methods_oboe));
    return JNI_VERSION_1_6;
}
```

这个timerPrepare是[[Study Log/android_study/ndk/2_simple_timer|2_simple_timer]]中的那些准备的逻辑：

```cpp
void timerPrepare(JavaVM *vm) {
    memset(&context, 0, sizeof(context));
    context.javaVm = vm;
    context.interrupted = false;
    context.simpleTimerObj = nullptr;
}
```

注意，这个方法不能是static，否则会报错：[makefile - C - Function has internal linkage but is not defined - Stack Overflow](https://stackoverflow.com/questions/51070909/c-function-has-internal-linkage-but-is-not-defined)

# 2 Oboe

## 2.1 Shared Library

Oboe的添加和使用：[oboe/docs/GettingStarted.md at main · google/oboe](https://github.com/google/oboe/blob/main/docs/GettingStarted.md#option-1-using-pre-built-binaries-and-headers)

我添加完的cmake文件：

```cmake
cmake_minimum_required(VERSION 3.22.1)
project("native-study")  # ${CMAKE_PROJECT_NAME}之后就是"native-study"
find_package(oboe REQUIRED CONFIG)  # 找到oboe库
add_library(${CMAKE_PROJECT_NAME} SHARED
        # List C/C++ source files with relative paths to this CMakeLists.txt.
        basic/simple_class_name.cpp
        basic/simple_timer.cpp
        oboe/hello_oboe.cpp
        main.cpp)
target_link_libraries(${CMAKE_PROJECT_NAME}
        # List libraries link to the target library
        android
        log
        oboe::oboe)  # 加上oboe
```

## 2.2 Oboe封装

我们封装最简单的功能。封装一个播放器，用开关`isOn`控制：

```cpp
#include "../common.h"
#include <math.h>
#include <oboe/Oboe.h>

using namespace oboe;

class OboeSinePlayer : public oboe::AudioStreamCallback {
public:
    OboeSinePlayer() {
        AudioStreamBuilder builder;
        builder.setSharingMode(SharingMode::Exclusive)
                ->setPerformanceMode(PerformanceMode::LowLatency)
                ->setFormat(oboe::AudioFormat::Float)
                ->setCallback(this)
                ->openManagedStream(outStream);
        channelCount = outStream->getChannelCount();
        mPhaseIncrement = kFrequency * kTwoPi / outStream->getSampleRate();
        outStream->requestStart();
    }

    DataCallbackResult
    onAudioReady(AudioStream *audioStream, void *audioData, int32_t numFrames) override {
        float *floatData = static_cast<float *>(audioData);
        if (isOn) {
            for (int i = 0; i < numFrames; ++i) {
                float sampleValue = kAmplitude * sinf(mPhase);
                for (int j = 0; j < channelCount; ++j) {
                    floatData[i * channelCount + j] = sampleValue;
                }
                mPhase += mPhaseIncrement;
                if (mPhase >= kTwoPi) mPhase -= kTwoPi;
            }
        } else {
            std::fill_n(floatData, numFrames * channelCount, 0);
        }
        return DataCallbackResult::Continue;
    }

    void enable(bool toEnable) { isOn.store(toEnable); }

private:
    oboe::ManagedStream outStream;

    std::atomic_bool isOn { false };
    int channelCount;
    double mPhaseIncrement;

    static float constexpr kAmplitude = 0.5f;
    static float constexpr kFrequency = 440;

    float mPhase = 0.0;

    static double constexpr kTwoPi = M_PI * 2;
};
```

具体咋实现的就先不管了，等有机会遇到Oboe再说吧。这里比较能学习的就是isOn的初始化方法：

```cpp
std::atomic_bool isOn { false };
```

这是C++11标准的初始化方法。根据`atomic<bool>`的构造函数的结构，逐个往里面传入值就可以了。

## 2.3 JNI Functions

oboe需要在`common.h`中添加的内容：

```cpp
jint createStream(JNIEnv *, jobject);
void destroyStream(JNIEnv *, jobject);
jint playSound(JNIEnv *, jobject thiz, jboolean);

static const std::string class_name_oboe = "com/spread/nativestudy/fragments/OboeFragment";
static Methods methods_oboe = {
        {"createStream", "()I", (void *)(createStream)},
        {"destroyStream", "()V", (void *)(destroyStream)},
        {"playSound", "(Z)I", (void *)(playSound)}
};
```

之后在`JNI_OnLoad()`中注册：

```cpp
registerJMethods(env, class_name_oboe, methods_oboe, SIZE_OF_METHOD(methods_oboe));
```

实现：

```cpp
#include "OboeSinePlayer.h"

static OboeSinePlayer *player = nullptr;

jint createStream(JNIEnv *env, jobject thiz) {
    player = new OboeSinePlayer();
    return player ? 0 : -1;
}

void destroyStream(JNIEnv *env, jobject thiz) {
    if (player == nullptr) return;
    delete player;
    player = nullptr;
}

jint playSound(JNIEnv *env, jobject thiz, jboolean enable) {
    jint result = 0;
    if (player) {
        player->enable(enable);
    } else {
        result = -1;
    }
    return result;
}
```

都非常简单，就不多说了。

最后，啥时候调用？看你了。我是等触摸到最外层的FrameLayout的时候就响，一松手就停。然后自己选时机去初始化和destroy就可以了：

```kotlin
override fun onResume() {
	super.onResume()
	if (createStream() != 0) {
		Log.e(TAG, "createStream failure")
		return
	}
	rootView.setOnTouchListener(this)
}

override fun onPause() {
	destroyStream()
	super.onPause()
}

override fun onTouch(v: View, event: MotionEvent): Boolean {
	if (v.id == R.id.oboe_framelayout) {
		when (event.actionMasked) {
			MotionEvent.ACTION_DOWN -> playSound(true)
			MotionEvent.ACTION_UP -> playSound(false)
		}
	}
	return true
}
```

- [ ] #TODO 其实不应该算在oboe里面，但是恰好遇到了。为啥这里会警告必须实现performClick()? ⏫

