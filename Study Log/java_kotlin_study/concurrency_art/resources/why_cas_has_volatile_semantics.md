在`jdk/src/hotspot/share/prims/unsafe.cpp`中定义了Unsafe类的native层实现。其中compareAndSetInt的实现如下：

```cpp
UNSAFE_ENTRY_SCOPED(jboolean, Unsafe_CompareAndSetLong(JNIEnv *env, jobject unsafe, jobject obj, jlong offset, jlong e, jlong x)) {
	oop p = JNIHandles::resolve(obj);
	volatile jlong* addr = (volatile jlong*)index_oop_from_field_offset_long(p, offset);
	return Atomic::cmpxchg(addr, e, x) == e;
} UNSAFE_END
```

- [ ] #TODO 这个UNSAFE_ENTRY_SCOPED有什么用？怎么设计的？

可以看到调用的就是Atomic中的cmpxchg函数来进行转换。而这个的实现位于`jdk/src/hotspot/share/runtime/atomic.hpp`。在Atomic类中可以看到这个函数的声明：

```cpp
// Performs atomic compare of *dest and compare_value, and exchanges
// *dest with exchange_value if the comparison succeeded. Returns prior
// value of *dest. cmpxchg*() provide:
// <fence> compare-and-exchange <membar StoreLoad|StoreStore>

template<typename D, typename U, typename T>
inline static D cmpxchg(D volatile* dest,
						U compare_value,
						T exchange_value,
						atomic_memory_order order = memory_order_conservative);
```

这里的最后一个参数给了默认值。所以之前调用的时候我们可以不传。接下来看看函数的实现：

```cpp
template<typename D, typename U, typename T>
inline D Atomic::cmpxchg(D volatile* dest,
						 U compare_value,
						 T exchange_value,
						 atomic_memory_order order) {
	return CmpxchgImpl<D, U, T>()(dest, compare_value, exchange_value, order);
}

// Handle cmpxchg for integral types.
//
// All the involved types must be identical.

template<typename T>
struct Atomic::CmpxchgImpl<
	T, T, T,
	typename EnableIf<std::is_integral<T>::value>::type>
{
	T operator()(T volatile* dest, T compare_value, T exchange_value,
	atomic_memory_order order) const {
	// Forward to the platform handler for the size of T.
	return PlatformCmpxchg<sizeof(T)>()(dest,
										compare_value,
										exchange_value,
										order);
	}
};
```

这里的PlatformCmpxchg对应着各个平台的实现。我们可以在`jdk/src/hotspot/os_cpu`中找到各种CPU的实现。以linux_x86为例，实现位于`jdk/src/hotspot/os_cpu/linux_x86/atomic_linux_x86.hpp`：

```cpp
template<>
template<typename T>
inline T Atomic::PlatformCmpxchg<4>::operator()(T volatile* dest,
												T compare_value,
												T exchange_value,
												atomic_memory_order /* order */) const {
	STATIC_ASSERT(4 == sizeof(T));
	__asm__ volatile ("lock cmpxchgl %1,(%3)"
						: "=a" (exchange_value)
						: "r" (exchange_value), "a" (compare_value), "r" (dest)
						: "cc", "memory");
	return exchange_value;
}
```

可以看到，也加了lock指令，这和volatile关键字的做法是一样的。而这个lock指令是作用于整个cmpxchg命令，所以读老值和写新值都是被lock住的。所以CAS操作才同时具有volatile的读写语义。