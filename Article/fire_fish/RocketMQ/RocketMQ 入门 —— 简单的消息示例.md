

### 可靠的同步传输
```java
public class SyncProducer {
	public static void main(String[] args) throws Exception {
		//Instantiate with a producer group name.
		DefaultMQProducer producer = new
				DefaultMQProducer("please_rename_unique_group_name");

		producer.setNamesrvAddr("127.0.0.1:9876");

		//Launch the instance.
		producer.start();
		for (int i = 0; i < 1; i++) {
			//Create a message instance, specifying topic, tag and message body.
			Message msg = new Message("TopicTest" /* Topic */,
					"TagA" /* Tag */,
					("Hello RocketMQ " +
							i).getBytes(RemotingHelper.DEFAULT_CHARSET) /* Message body */
			);
			//Call send message to deliver message to one of brokers.
			SendResult sendResult = producer.send(msg);
//            System.out.printf("%s%n", sendResult);
			System.out.printf("%-10d OK %s %n", i, sendResult.getMsgId());      // 从打印的日志可以看出是"同步"
		}
		//Shut down once the producer instance is not longer in use.
		producer.shutdown();
	}
}
```
> 原理：this.remotingClient.invokeSync

### 可靠的异步传输
```java
public class AsyncProducer {
	public static void main(String[] args) throws Exception {
		//Instantiate with a producer group name.
		DefaultMQProducer producer = new DefaultMQProducer("ExampleProducerGroup");

		producer.setNamesrvAddr("127.0.0.1:9876");

		//Launch the instance.
		producer.start();
		producer.setRetryTimesWhenSendAsyncFailed(0);
		for (int i = 0; i < 2; i++) {
			final int index = i;
			//Create a message instance, specifying topic, tag and message body.
			Message msg = new Message("TopicTest",
					"TagA",
					"OrderID188",
					"Hello world".getBytes(RemotingHelper.DEFAULT_CHARSET));
			producer.send(msg, new SendCallback() {
				@Override
				public void onSuccess(SendResult sendResult) {
					System.out.printf("%-10d OK %s %n", index,
							sendResult.getMsgId());     // 从打印的日志可以看出是"异步"
				}
				@Override
				public void onException(Throwable e) {
					System.out.printf("%-10d Exception %s %n", index, e);
					e.printStackTrace();
				}
			});
		}

		Thread.sleep(20000);
		//Shut down once the producer instance is not longer in use.
		producer.shutdown();
	}
}
```
> this.remotingClient.invokeAsync
### 单向传输
```java
public class OnewayProducer {
    public static void main(String[] args) throws Exception{
        //Instantiate with a producer group name.
        DefaultMQProducer producer = new DefaultMQProducer("ExampleProducerGroup");

        producer.setNamesrvAddr("127.0.0.1:9876");

        //Launch the instance.
        producer.start();
        for (int i = 0; i < 100; i++) {
            //Create a message instance, specifying topic, tag and message body.
            Message msg = new Message("TopicTest" /* Topic */,
                "TagA" /* Tag */,
                ("Hello RocketMQ " +
                    i).getBytes(RemotingHelper.DEFAULT_CHARSET) /* Message body */
            );
            //Call send message to deliver message to one of brokers.
            producer.sendOneway(msg);

        }
        //Shut down once the producer instance is not longer in use.
        producer.shutdown();
    }
}
```
> 原理：this.remotingClient.invokeOneway
