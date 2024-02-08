```java
/**
 * Figures out the measure spec for the root view in a window based on it's
 * layout params.
 *
 * @param windowSize The available width or height of the window.
 * @param measurement The layout width or height requested in the layout params.
 * @param privateFlags The private flags in the layout params of the window.
 * @return The measure spec to use to measure the root view.
 */
private static int getRootMeasureSpec(int windowSize, int measurement, int privateFlags) {
	int measureSpec;
	final int rootDimension = (privateFlags & PRIVATE_FLAG_LAYOUT_SIZE_EXTENDED_BY_CUTOUT) != 0
			? MATCH_PARENT : measurement;
	switch (rootDimension) {
		case ViewGroup.LayoutParams.MATCH_PARENT:
			// Window can't resize. Force root view to be windowSize.
			measureSpec = MeasureSpec.makeMeasureSpec(windowSize, MeasureSpec.EXACTLY);
			break;
		case ViewGroup.LayoutParams.WRAP_CONTENT:
			// Window can resize. Set max size for root view.
			measureSpec = MeasureSpec.makeMeasureSpec(windowSize, MeasureSpec.AT_MOST);
			break;
		default:
			// Window wants to be an exact size. Force root view to be that size.
			measureSpec = MeasureSpec.makeMeasureSpec(rootDimension, MeasureSpec.EXACTLY);
			break;
	}
	return measureSpec;
}
```