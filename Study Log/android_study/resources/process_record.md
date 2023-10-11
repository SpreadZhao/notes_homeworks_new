```java
/**
 * List of running applications, sorted by recent usage.
 * The first entry in the list is the least recently used.
 */
@CompositeRWLock({"mService", "mProcLock"})
private final ArrayList<ProcessRecord> mLruProcesses = new ArrayList<ProcessRecord>();
```