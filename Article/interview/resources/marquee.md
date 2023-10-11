```xml
<LinearLayout  
    android:layout_width="match_parent"  
    android:layout_height="wrap_content"  
    android:orientation="horizontal">  
  
    <EditText        
	    android:id="@+id/control_marquee"  
        android:layout_width="0dp"  
        android:layout_height="wrap_content"  
        android:layout_weight="1"  
        />  
  
    <Button        
	    android:id="@+id/submit"  
        android:layout_width="wrap_content"  
        android:layout_height="wrap_content"  
        android:text="Submit"  
        />  
</LinearLayout>  
  
<com.example.customviewtest.MarqueeText  
    android:id="@+id/marquee"  
    android:layout_width="100dp"  
    android:layout_height="wrap_content"  
    />
```