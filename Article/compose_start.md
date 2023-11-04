Jetpack Compose start tutorial. Referencing:

[A Glimse Into Jetpack Compose By Building an App | by Aldo Surya Ongko | Better Programming](https://betterprogramming.pub/a-glimse-into-jetpack-compose-by-building-an-app-a7869723d4e8)

You can see my progress here:

[compose_tutorial: My start on Google Jetpack Compose. (gitee.com)](https://gitee.com/spreadzhao/compose_tutorial)

# 1. HomeScreen

The core idea of Jetpack Compose is **transferring all xml layout files into kotlin files**. To implement this, Google published **Composable Functions**, which can be used like any layout or views. We can declare a Composable Function in another Composable Function just like putting a ListView in a LinearLayout. The demo below is supposed to be like this:

![[Article/resources/Screenshot_20230408_223849_ComposeTutorial.jpg|200]]  ![[Article/resources/Screenshot_20230408_223852_ComposeTutorial.jpg|200]]

An [OutlinedTextField](https://developer.android.com/jetpack/compose/text#enter-modify-text) on the top, and a RecyclerView-like List below, with 3 columns. This file is called **HomeScreen.kt** which is a kotlin file instead of a kotlin class, because what we are coding is function but not xml or it's corrisponding object.

```kotlin
@Composable  
fun HomeScreen(  
    modifier: Modifier = Modifier,   
){  
    var text by remember{ mutableStateOf("") }  
    Column {  
        OutlinedTextField(  
            modifier = modifier.fillMaxWidth(),  
            value = text,  
            onValueChange = {text = it},  
            label = { Text(text = "Param to pass") },  
        )  
  
        LazyVerticalGrid(  
            modifier = Modifier.padding(16.dp),   
            columns = GridCells.Adaptive(minSize = 96.dp),  
            verticalArrangement = Arrangement.spacedBy(16.dp),  
            horizontalArrangement = Arrangement.spacedBy(16.dp),  
        ){  
            for(i in 1..60){
                item {  
                    ProductCard(name = i.toString())  
                }  
            }  
        }
    }  
}
```

Every composable function is configured by it's param **modifier**, which is just like the various properties in a xml layout file. So we can easily pass the value **from parent to it's child to reuse those functionalities**. There's a trick in the codes above, which is the for loop in a composable function. That means I created 60 ProductCard indexed from 1 to 60, which seems a harder job in xml based coding.

The detail implementation of ProductCard will be talked about before long, but that of LazyVertical Grid is illustrated by Google [here](https://developer.android.com/jetpack/compose/lists).

Now let's turn to the element in the list - ProductCard, **which is a composable function itself.** Look! We create two composable functions, and put one in another, **without xml layout inflating or function overriding**. Such technique is sure to be fluent and neat for coders.

```kotlin
@OptIn(ExperimentalMaterialApi::class)  
@Composable  
fun ProductCard(  
    modifier: Modifier = Modifier,  
    name: String = "" 
){  
    Column(  
        modifier = modifier,  
        horizontalAlignment = Alignment.CenterHorizontally,  
    ) {  
        Card() {  
            Image(
                painter = painterResource(id = R.drawable.ic_launcher_foreground),  
                contentDescription = null,  
                modifier = Modifier  
                    .size(40.dp)  
                    .clip(CircleShape)  
                    .border(1.dp, MaterialTheme.colors.secondary, CircleShape)  
            )  
        }  
        Text(  
            text = name  
        )  
    }  
}
```

> *member `name` will be explained later*.

The constructor of ProductCard have two params: modifier and name. The former is the common property in every composable function, and the later is the number under the icon like the number 8 below:

![[Article/resources/Pasted image 20230408230220.png|50]]

Because `Alignment.CenterHorizontally` is still an experimental api, so we annotate it at first. Notice that, the passing by of params in HomeScreen to ProductCard does not include the modifier, so in the case above, the 1st param modifier will be it's defalt value - a newer Modifier:

```kotlin
fun ProductCard(  
    modifier: Modifier = Modifier,  
```

But in my final implementation, you will notice that I have deleted some details for the sake of tutorial.

# 2. DetailScreen

In our MainActivity, you will have done all the things just by putting HomeScreen in it:

```kotlin
class MainActivity : ComponentActivity() {  
    override fun onCreate(savedInstanceState: Bundle?) {  
        super.onCreate(savedInstanceState)  
        setContent {  
            ComposeTutorialTheme {  
                HomeScreen()
            }  
        }    
    }  
}
```

I will not do that, however, for making a bigger and fancier demo. Next let's turn to the second screen of our program: DetailScreen, which looks like this:

![[Article/resources/Screenshot_20230409_121604_ComposeTutorial.jpg|200]]

A header with picture and text on the top, a slidable image carousel in the middle, and the detail text. As you will see, I will arrange them spontaneously in a column with Jeppack Compose:

```kotlin
@Composable  
fun DetailScreen(  
    modifier: Modifier = Modifier,  
    id: Int = 0  
){  
    val scrollState = rememberScrollState()  
    Column(  
        modifier = modifier  
            .fillMaxWidth()  
            .verticalScroll(scrollState) // Make it scrollable  
    ) {  
        ProductHeader(  
            modifier = Modifier.padding(16.dp)  
        )  
        ProductImageCarousel(  
            modifier = Modifier  
                .height(200.dp)  
                .fillMaxWidth()  
        )  
        val str = StringBuilder()  
        repeat(1000){  
            str.append("spread ")  
        }  
        Text(text = str.toString())  
        Text(text = "param: $id")  
    }  
}
```

Modifier has a member to make the view scrollable, which is the `scrollState`. Details about it:

[Gestures  |  Compose  |  Android Developers](https://developer.android.com/jetpack/compose/touch-input/gestures)

Now let's realize the compose referenced by the screen - ProductHeader and ProductImageCarousel, just like the ProductCard above.

```kotlin
@Composable  
fun ProductHeader(  
    modifier: Modifier = Modifier  
){  
    ConstraintLayout(  
        modifier = modifier  
    ){  
        val(  
            photoAvatar,  
            nameText,  
            titleText  
        ) = createRefs()  
  
        Image(  
            painter = painterResource(id = R.drawable.ic_launcher_foreground),  
            contentDescription = null,  
            modifier = Modifier  
                .size(96.dp)  
                .clip(CircleShape)  
                .border(1.dp, MaterialTheme.colors.secondary, CircleShape)  
                .constrainAs(photoAvatar) {  
                    start.linkTo(parent.start)  
                    top.linkTo(parent.top)  
                    bottom.linkTo(parent.bottom)  
                }  
        )  
  
        Text(  
            text = "hehe",  
            maxLines = 1,  
            overflow = TextOverflow.Ellipsis,  
            fontSize = 20.sp,  
            fontWeight = FontWeight.Bold,  
            modifier = Modifier  
                .constrainAs(nameText) {  
                    start.linkTo(photoAvatar.end, 16.dp)  
                    top.linkTo(parent.top)  
                }  
        )  
    }  
}
```

We use a [ConstraintLayout](https://developer.android.com/jetpack/compose/layouts/constraintlayout) to lying those sub views in it, **which makes every modifier in it restrain itself by the newer property - constrainAs**. in it's constructor, we can configure how the current view is related with other views **by the references we create ahead**:

```kotlin
val(  
	photoAvatar,  
	nameText,  
	titleText  
) = createRefs()
```

Take the text as an example. We make the start of the text linked to the end of the previous view photoAvatar, and the top of it to the top of it's parent, which is DetailScreen. So the general layout looks like this:

![[Article/resources/Pasted image 20230409124236.png|400]]

Second is ProductImageCarousel, which is simply a [HorizontalPager](https://developer.android.com/jetpack/compose/layouts/pager) with 6 alike pictures in it:

```kotlin
@OptIn(ExperimentalFoundationApi::class)  
@Composable  
fun ProductImageCarousel(  
    modifier: Modifier = Modifier  
){  
    val state = rememberPagerState()  
    HorizontalPager(  
        state = state,  
        pageCount = 6,  
        modifier = modifier  
    ) {  
        Box(  
            modifier = Modifier.fillMaxSize(),  
            contentAlignment = Alignment.Center  
        ){  
            Image(  
                painter = painterResource(id = R.drawable.ic_launcher_foreground),  
                contentDescription = "",  
                modifier = Modifier  
                    .padding(  
                        start = 8.dp,  
                        end = 8.dp  
                    )  
                    .clip(RoundedCornerShape(10.dp))  
                    .fillMaxSize(),  
                contentScale = ContentScale.Crop  
            )  
        }  
    }
}
```

# 3. Navigation

Now we have two separate views, but how to navigate from one to the other? Instead of Intent in traditional Android programming, navigation is sealed in the compose by NavController:

[Navigating with Compose  |  Android Developers](https://developer.android.com/jetpack/compose/navigation)

Before we start navigating, we should recognize our UI architecture:

![[Article/resources/Pasted image 20230409125457.png|400]]

Regardless of the screens, **we can navigate from HomeFragment to DetailFragment, with the help of MainActivity**. So we should first contain the HomeScreen in HomeFragment, and the DetailScreen in DetailFragment:

```kotlin
@Composable  
fun HomeFragment(  
    modifier: Modifier = Modifier,   
) {  
  
    Surface(  
        modifier = Modifier.fillMaxSize(),  
        color = MaterialTheme.colors.background  
    ) {  
        HomeScreen(  
            modifier = Modifier  
                .padding(horizontal = 16.dp),   
        )  
    }  
}
```

```kotlin
@Composable  
fun DetailFragment(  
    modifier: Modifier = Modifier,  
    id: Int = 0,  
){  
    Surface(  
        modifier = modifier.fillMaxSize(),  
        color = MaterialTheme.colors.background  
    ) {  
        DetailScreen(modifier = modifier, id = id)  
    }  
}
```

A quote of the article of navigation above:

> You should create the `NavController` in the place in your composable hierarchy where all composables that need to reference it have access to it.

So we should create our NavHost here. Create `ComposeTutorialAppScreen()` function in MainActivity.kt and fill it like this:

```kotlin
@Composable  
fun ComposeTutorialAppScreen() {  
    val navController = rememberNavController()  
    NavHost(  
        navController = navController,  
        startDestination = "Home" 
    ){  
        composable(route = "Home") {
			HomeFragment()
		}
		composable(route = "Detail") {
			DetailFragment()
		}
    }
}
```

If you have read that article, you will know what do these codes mean. However, the direct usage of a String is always not secure, so we take the advantage of the **sealed classs** in kotlin to impove it:

```kotlin
sealed class Route(val route: String) {
    object Home: Route("Home")
    object Detail: Route("Detail")
}
```

And the function can be recoded like this:

```kotlin
@Composable
fun ComposeTutorialAppScreen() {
    val navController = rememberNavController()
    NavHost(
        navController = navController,
        startDestination = Route.Home.route,
    ) {
        composable(route = Route.Home.route) {
            HomeFragment()
        }
        composable(route = Route.Detail.route) {
            DetailFragment()
        }
    }
}
```

All the works above are just a **registration** for navigation but the real action. We need further coding to realize it. Summarily, once we click on the card in the HomeScreen, the DetailScreen will open. Thus the eventual navigation will apear from here:

```kotlin
@OptIn(ExperimentalMaterialApi::class)  
@Composable  
fun ProductCard(  
    modifier: Modifier = Modifier,  
    name: String = "" 
){  
    Column(  
        modifier = modifier,  
        horizontalAlignment = Alignment.CenterHorizontally,  
    ) {  
        Card(onClick = someThingWillHappen) {  
            Image(
                painter = painterResource(id = R.drawable.ic_launcher_foreground),  
                contentDescription = null,  
                modifier = Modifier  
                    .size(40.dp)  
                    .clip(CircleShape)  
                    .border(1.dp, MaterialTheme.colors.secondary, CircleShape)  
            )  
        }  
        Text(  
            text = name  
        )  
    }  
}
```

The next question is: what is the `someThingWillHappen`? As you will know, the `navController` related to the `NavHost` has a function `navigate()` whose parameter is just the **route** we configured above. So the answer is: we should make the `someThingWillHappen` the `navigate()` method, which we have done in C where we pass a **Function Pointer** as parameter. In kotlin, the technique is called **High-order Functions** which is introduced in 《第一行代码》chapter 6.5.

What we will do is passing the lambda(contains `navigate()` method) from MainActivity to the specifit card **along the way**. So we should add a lamba member for all the mentioned composables:

```kotlin
@OptIn(ExperimentalMaterialApi::class)  
@Composable  
fun ProductCard(  
    modifier: Modifier = Modifier,  
    onclickProduct: () -> Unit = {},  
    name: String = ""  
){
... ...
```

```kotlin
@Composable  
fun HomeScreen(  
    modifier: Modifier = Modifier,  
    onClickToDetailScreen: () -> Unit = {}  
){
... ...
```

```kotlin
@Composable  
fun HomeFragment(  
    modifier: Modifier = Modifier,  
    onClickToDetailScreen: () -> Unit = {}  
) {
... ...
```

> The real passing of prameter was ignored here.

Finally reformat the NavHost in MainActivity:

```kotlin
@Composable
fun ComposeTutorialAppScreen() {
    val navController = rememberNavController()
    NavHost(
        navController = navController,
        startDestination = Route.Home.route,
    ) {
        composable(route = Route.Home.route) {
            HomeFragment(
	            onClickToDetailScreen = {
		            navController.navigate(Route.Detail.route)
	            }
            )
        }
        composable(route = Route.Detail.route) {
            DetailFragment()
        }
    }
}
```

But how to navigate with arguments like using Intent in traditional android developing? Have a read of the follow article:

[Navigating with Compose  |  Android Developers](https://developer.android.com/jetpack/compose/navigation#nav-with-args)

And you can easily know the following change of `ComposeTutorialAppScreen()` function:

```kotlin
@Composable  
fun ComposeTutorialAppScreen() {  
    val navController = rememberNavController()  
    NavHost(  
        navController = navController,  
        startDestination = Route.Home.route  
    ){  
        composable(route = Route.Home.route) {  
            HomeFragment(  
                onClickToDetailScreen = { gamesId ->  
                    navController.navigate(Route.Detail.createRoute(gamesId))  
                }  
            )  
        }  
        composable(  
            route = Route.Detail.route,  
            arguments = listOf(  
                navArgument("gamesId"){  
                    type = NavType.IntType  
                }  
            )  
        ) { backstackEntry ->  
            val gamesId = backstackEntry.arguments?.getInt("gamesId")  
            requireNotNull(gamesId){  
                "gamesId param unset."  
            }  
            DetailFragment(Modifier, gamesId)  
        }  
    }
}
```

By the way, the sealed class Route was also reformed:

```kotlin
sealed class Route(val route: String){  
    object Home: Route("Home")  
    object Detail: Route("Detail/{gamesId}"){  
        fun createRoute(gamesId: Int) = "Detail/$gamesId"  
    }  
}
```

