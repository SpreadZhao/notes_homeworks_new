# 2023-4-25

The logic of NIO's **Car Search Service** relies on a series of underlying services for implementation. For the search service may always be killed by os, we need a **permanent** process to handle the **status and the transition of them** for each component in our program.

So far we have known four occasions where the **Car Search Service** will be invoked:

* Account behavior(log in, log out);
* Connecting with car(SOA);
* UWB signal(when get out of or in car);
* Launching the Car Control Card App(Side key of the phone).

In these four cases, we should manually invoke our initial app to register our services to offer supplement for the next operations such as parking space recognition.

All the registry behaviors were defined in a singleton Java class called **InitManager**, we manage all the relative functions here. The entry func is called `init()`, which is triggered by Java Reflect temporarily in the occasions above:

```java
public void init() {
	if(isInit.getAndSet(true)) {
		return;
	}
	...
	SearchSignalService.getInstance().init();
	PositionInitTask.getInstance().init(null);
	MapEngineInitTask.getInstance().init();
	LocationProxy.getInstance().init();
	fetchTask.loop();
}
```

^9eabae

> Notice that these functions were attached to the **Vehicle Management Service(VMS)** process, so we need to check out the curr proc when debugging.

Now we make a simple mock on the trigger stack internal. The Main Application launched by the side key of the phone is not a traditional app with a main activity, but a built-in-system app with a series of permanent processes. So we need to **customize** our own Application to provide services. Look at our AndroidManifest.xml **in main App**:

```xml
<application
	android:name="com.skyui.vehicle.SkyVehicleApplication"
	...>
	
	<activity
		android:name="xxx.VehicleControlTransActivity"
		...
	>	
	</activity>

	<activity
		android:name="xxx.MockAccountActivity"
		...
	>	
	</activity>

	
</application>
```

The customized Application is called SkyVehicleAppication, which is extended from BaseApplication of us:

```kotlin
class SkyVehicleApplication : BaseApplication()
```

> All our stories after clicking the side key of the phone starts from here.

In BaseApplication, we check **if the current process is the process we want**, and do the corresponding opreations. But why we have to do that? This logic is implemented in the `onCreate()` of an Application. So once the application start, the codes will be run by one time. Of course our **Car Search Service** is included in that. Once the SkyVehicleApplication start, all of the **sub components** of that process will be initialized properly.

So, what is the **process we want**? The answer is:

```kotlin
open class BaseApplication: Application() {
	override fun onCreate() {
		super.onCreate()
		...
		if (getProcessName == "com.skyui.vehicle:VMS") {
			// do Init
		}
	}
}
```

NIO underlying launch logic(AOSP) has described that,  #question ~~(all of 4?)~~ **once we receive an SOA broadcast from the car, the `onCreate()` function of an Application class will be run**, so we can do our registration(init) here. However, you may confuse that we do not have a process called `"com.skyui.vehicle:VMS"` in AndroidManifest.xml above, how can we get in the `onCreate()` function? The SkyVehicleApplication was extended from Application, but in another AndroidManifest.xml of **Car Search Service**, we use an anonymous one:

```xml
<application>
	<receiver
		android:process="VMS"
	>
	<provider
		android:process="VMS"
	>
	...
</application>
```

> This application is exactly what we concerned instead of the one above.

During the compiling process of the main app, all of the AndroidManifest.xml will be integrated into one unit. **An application without name will be merged into one with name**, so these two separated xmls are actually of the same name. This technique make us enabled to check different process tags in the `onCreate()` logic, such as:

```kotlin
if (getProcessName == "com.skyui.vehicle:VMS") {
	// do Init
}
```

What is `do Init`? Obviously the registration of services such as:

* Checking and using SOA Connection(s);
* Getting information from car device(s);
* Initialize the car(s) state.

#question ~~Is that true?~~

Beyond these features, there're also some **listeners** to check out the change of status. Actually, those functions are just contained in the core function `init()` [[#^9eabae|above]]. However, just as what we have talked about, the trigger is currently mocked with Java Reflection. So we should do reflection here in `do Init` and call `init()`:

```java
if (getProcessName == "com.skyui.vehicle:VMS") {
	try {
		val clazz = Class.forName("com.skyui.vehicleservice.search.init.InitManager")
		val instance = clazz.getMethod("newInstance").invoke(clazz)
		clazz.getMethod("init").invoke(instance)
	} catch (e: Exception) {
		e.printStackTrace()
	}
}
```

# 2023-4-26

Now let's get in the running of `init()` function in InitManager. There're only some singleton classes here and the only thing to do is to initialize them:

```java
public void init() {
	...
	SearchSignalService.getInstance().init();
	PositionInitTask.getInstance().init(null);
	MapEngineInitTask.getInstance().init();
	LocationProxy.getInstance().init();
	fetchTask.loop();
}
```

Let's dig into their's internal literally. The only thing `SearchSignalService` initialized is the request of SOA Status Machine:

```java
public class SearchSignalService {
	...
	public void init() {
		requestConnectStatus(ActivityThread.currentApplication());
	}
	...
}
```

Currently we don't care what does this sentence mean, let's dig into the deepest to see what we really do:

```java
public class SearchSignalService {
	...
	public void init() {
		requestConnectStatus(ActivityThread.currentApplication());
	}

	private void requestConnectStatus(Context context) {
		final String currentVid = VehicleControlService.INSTANCE.getVehicleService().getCurrentVid();
		...
		MessageMgr.getInstance().reqConnectionState(context, currentVid, mMessagegListener);
	}
	...
}
```

^acd839

The first sentence in `requestConnectStatus()` means we need to know **which car we are connected to now** and get its VID(Vehicle ID).

> We don't need to get VID from underlying biz here, for a phone can only connect to one specific car one time.

After that, we can do some initialization and **the registration of listener**, which is the last sentence of the function.

```java
public class MessageMgr {
	...
	public void reqConnectionState(Context context, String vid, IMessageListener listener) {
		setMessageListener(listener);
		mMessageLink.reqConnectionState(context, vid);
	}
	...
	public void setMessageListener(IMessageListener listener) {
		mMessageLink.setMessageListener(listener);
	}
	...
}
```

Let's focus on the following sentence first:

```java
mMessageLink.reqConnectionState(context, vid);
```

```java
public class SOAConnection implements IMessageLink {
	...
	@Override
	public void reqConnectionState(Context context, String vid) {
		...
		context.sendBroadcast(intent, SAFETY_COMPONENT_PERMISSION);
	}
}
```

This broadcast is **sent by Car Search App(you can get that by tracking the context), and received by Nearby App**. So we do not connect to the car directly. Notice that the SOAConnection class implemented the interface IMessageLink, which obeys the **Dependency Inversion Principle** in OOP programming:

![[Projects/nio/resources/Drawing 2023-04-26 10.46.24.excalidraw.png]]

After that, let's turn to the other sentence in `reqConnectionState()` in MessageMgr:

```java
setMessageListener(listener);
```

You may have noticed that, this function is also wrapped in MessageMgr:

```java
public class MessageMgr {
	...
	public void reqConnectionState(Context context, String vid, IMessageListener listener) {
		setMessageListener(listener);
		mMessageLink.reqConnectionState(context, vid);
	}
	...
	public void setMessageListener(IMessageListener listener) {
		mMessageLink.setMessageListener(listener);
	}
	...
}
```

All the listeners in SOAConnection are managed in a CopyOnWriteArrayList:

```java
public class SOAConnection implements IMessageLink {
	...
	private List<IMessageListener> listeners = new CopyOnWriteArrayList<>();

	@Override
	public void setMessageListener(IMessageListener listener) {
		if(listener != null && !listeners.contains(listener)) {
			listeners.add(listener);
		}
	}
	...
}
```

The next question is: What is the listener? SearchSignalService has its own listener which is just the param above [[#^acd839|mMessageListener]]. We implement it's callback functions here, and call them in SOAConnection:

```java
public class SearchSignalService {
	...

	private final IMessageListener mMessageListener = new IMessageListener() {
		@Override
		public void onGearState()...

		@Override
		public void onFileInfo()...
	
		@Override
		public void onConnectionState()...
	}

	public void init() {
		requestConnectStatus(ActivityThread.currentApplication());
	}

	private void requestConnectStatus(Context context) {
		final String currentVid = VehicleControlService.INSTANCE.getVehicleService().getCurrentVid();
		...
		MessageMgr.getInstance().reqConnectionState(context, currentVid, mMessagegListener);
	}
	...
}
```

```java
public class SOAConnection implements IMessageLink {
	...
	@Override
	public void dispatchMessage(Intent intent) {
		...
		switch (action) {
			case ACTION_GEAR_STATE:
				...
				listener.onGearState(vid, gear);
				break;
			case ACTION_SOA_STATE:
				...
				listener.onConnectionState(vid, ...)
				...
		}
	}
	...
}
```

> **But, at 11:35 in April 26th, we have updated our logic to interconnect with Nearby App by SOASdk**. Now the code in MessageMgr have been changed to:
> 
> ```java
> public class MessageMgr {
> 	...
> 	private final SOASdk soaSdk = new SOASdk();
> 	...
> 	public void reqConnectionState(Context context, String vid, IMessageListener listener) {
> 		setMessageListener(listener);
> 		soaSdk.reqConnectionState(context, vid);
> 	}
> 	...
> 	public void setMessageListener(IMessageListener listener) {
> 		mMessageLink.setMessageListener(listener);
> 	}
> 	...
> }
> ```

---

After that, we should make another listen logic called **PositionListener**, which corresponds to the following code:

```java
public class InitManager {
	...
	public void init() {
		...
		PositionInitTask.getInstance().init(null);
		...
	}
	...
}
```

After we've get enough information, we're able to register another listener:

```java
public class PositionInitTask {
	...
	private IPositionListener mPositionListener = new IPositionListener() {
		@Override
		public void onStatus(Map<String, Integer> map) {
			...
		}
	}
	...
	public void init() {
		...
		mPositionListener.onStatus(currentState);
	}
}
```

> Cause there's only one method in interface IPositionListener, so we can optimize like this:
> 
> ```java
> public class PositionInitTask {
> private IPositionListener mPositionListener = map -> {
> 	...
> }
> ```

In this callback function, we need to **prepare the information of location for every car** to display to users, and the information were already wrapped in this map param. ~~You should know that this function will not be called immidiately, but when the remote component invoke.~~

---

The third one, MapEngineInitTask in InitManager, is the **indoor** map of NIO Car Search App; and the last one is the LocationProxy which idicates our latitude and longitude.

So, what do we do in every **listener**? When the listener receive information from Nearby App, the corresponding biz logic should be triggered(Go back to see the codes of every listener, you will get it). This must include the **change of status in every Status Machine**. 

At present, we have introduced all of the State Machines:

- [x] Connection State Machine
- [x] Position State Machine
- [x] Search Vehicle State Machine

However, we have not currently initialize them. So the final step of the `init()` function is to do this.

```java
public void init() {
	if(isInit.getAndSet(true)) {
		return;
	}
	...
	SearchSignalService.getInstance().init();
	PositionInitTask.getInstance().init(null);
	MapEngineInitTask.getInstance().init();
	LocationProxy.getInstance().init();
	fetchTask.loop();  // Initialize the State Machines.
}
```

This method will finally initialize the three machines of every car.