---
layout: post
category: CustomView
title: 安卓自定义View进阶-画笔基础(Paint)
tags: Android,Paint
keywords: Paint, getFillPath, StrokeMiter, 自定义View详解, 自定义控件, 安卓, Android, CustomView, GcsSloop
excerpt: Android Paint，。

typora-root-url: ../../../../Source
typora-copy-images-to: ./assets/customview/paint
---

在Android自定义View系列文章中，前面的部分有详细的讲解画布(Canvas)的功能和用法，但是和画布(Canvas)共同出现的画笔(Paint)却没有详细的讲解，本文带大家较为详细的了解一下画笔的相关内容。

> Paint 在英文中作为名词时主要含义是涂料，油漆，颜料的意思，作为动词则具有绘画、粉刷的意思，不过在程序相关的中文博客里面，Paint 通常被解释为画笔，本文也将采用这种翻译，因此本文里面提到的画笔如没有特殊表明就指代 Paint。

## 0.引子

通过本系列前面的文章知道，View 上的内容是通过 Canvas 绘制出来的，但 Canvas 中的大多数绘制方法都是需要 Paint 作为参数的，例如 `canvas.drawCircle(100, 100, 50, paint)` 最后就需要传递一个 Paint。这是为什么呢？

因为画布本身只是呈现的一个载体，真正绘制出来的效果却要取决于画笔，就像同样白纸，要绘制一幅山水图，用毛笔画和用铅笔画的效果肯定是完全不同的，决定不同显示效果的并不是画布(Canvas), 而是画笔(Paint)。

同样，在程序设计中也采用的类似的设计思想，画布的 draw 方法只是规定了所需要绘制的是什么东西，但具体绘制出什么效果则通过画笔来控制。  
例如： `canvas.drawCircle(100, 100, 50, paint)`，这个方法说明了要在坐标 (100, 100) 的位置绘制一个半径为 50 的圆，但是这个圆具体要绘制成什么样子却没有明确的表明，圆的颜色，圆环还是圆饼等都没有明确的指示，而这些内容正存在于画笔之中。

## 1. 内容概览

既然是介绍画笔，自然要先总览一下它都有哪些功能，下面简要的列出一些本文中会涉及到的内容。

### 1.1 内部类

| 类型  | 简介                                                         |
| ----- | ------------------------------------------------------------ |
| enum  | **Paint.Cap**<br/>Cap指定了描边线和路径(Path)的开始和结束显示效果。 |
| enum  | **Paint.Join**<br/>Join指定线条和曲线段在描边路径上连接的处理。 |
| enum  | **Paint.Style**<br/>Style指定绘制的图元是否被填充，描边或两者均有(以相同的颜色)。 |

### 1.2 常量

| 类型 | 简介                                                         |
| ---- | ------------------------------------------------------------ |
| int  | **ANTI_ALIAS_FLAG**<br/>开启抗锯齿功能的标记。               |
| int  | **DITHER_FLAG**<br/>在绘制时启用抖动的标志。                 |
| int  | **FILTER_BITMAP_FLAG**<br/>绘制标志，在缩放的位图上启用双线性采样。 |


### 1.3 构造方法

| 构造方法           | 摘要                                                |
| ------------------ | --------------------------------------------------- |
| Paint()            | 使用默认设置创建一个新画笔。                        |
| Paint(int flags)   | 创建一个新画笔并提供一些特殊设置(通过 flags 参数)。 |
| Paint(Paint paint) | 创建一个新画笔，并使用指定画笔参数初始化。          |

### 1.4 公开方法

画笔有 100 个左右的公开方法，限于篇幅，在本文中只会列举一部分方法，其余的内容，则放置于后续文章中再详细介绍。

| 返回值      | 简介                                                         |
| ----------- | ------------------------------------------------------------ |
| int         | **getFlags()**<br />获取画笔相关的一些设置(标志)。           |
| int         | **getFlags()**<br />获取画笔相关的一些设置(标志)。           |
| void        | **setFlags(int flags)**<br />设置画笔的标志位。              |
| void        | **set(Paint src)**<br />复制 src 的画笔设置。                |
| void        | **reset()**<br />将画笔恢复为默认设置。                      |
| int         | **getAlpha()**<br />只返回颜色的alpha值。                    |
| void        | **setAlpha(int a)**<br />设置透明度。                        |
| int         | **getColor()**<br />返回画笔的颜色。                         |
| void        | **setColor(int color)**<br />设置颜色。                      |
| void        | **setARGB(int a, int r, int g, int b)**<br />设置带透明通道的颜色。 |
| float         | **getStrokeWidth()**<br />返回描边的宽度。                   |
| void          | **setStrokeWidth(float width)**<br />设置线条宽度。          |
| Paint.Style   | **getStyle()**<br />返回paint的样式，用于控制如何解释几何元素（除了drawBitmap，它总是假定为FILL_STYLE）。 |
| void          | **setStyle(Paint.Style style)**<br />设置画笔绘制模式(填充，描边，或两者均有)。 |
| Paint.Cap     | **getStrokeCap()**<br />返回paint的Cap，控制如何处理描边线和路径的开始和结束。 |
| void          | **setStrokeCap(Paint.Cap cap)**<br />设置线帽。              |
| Paint.Join    | **getStrokeJoin()**<br />返回画笔的笔触连接类型。            |
| void          | **setStrokeJoin(Paint.Join join)**<br />设置连接方式。       |
| float         | **getStrokeMiter()**<br />返回画笔的笔触斜接值。用于在连接角度锐利时控制斜接连接的行为。 |
| void          | **setStrokeMiter(float miter)**<br />设置画笔的笔触斜接值。用于在连接角度锐利时控制斜接连接的行为。 |
| PathEffect    | **getPathEffect()**<br />获取画笔的 patheffect 对象。        |
| PathEffect    | **setPathEffect(PathEffect effect)**<br />设置 Path 效果。   |
| boolean     | **getFillPath(Path src, Path dst)**<br />将任何/所有效果（patheffect，stroking）应用于src，并将结果返回到dst。<br />结果是使用此画笔绘制绘制 src 将与使用默认画笔绘制绘制 dst 相同（至少从几何角度来说是这样的）。 |


## 2. 画笔介绍

由于画笔需要控制的内容也相当的多，因此它内部包含了相当多的属性变量，配置起来也相当繁杂，不过比较好的是，画笔会提供一套默认设置来供我们使用。例如，创建一个新画笔，这个新画笔已经默认设置了绘制颜色为黑色，绘制模式为填充。

### 2.1 画笔基本设置

要使用画笔就要会创建画笔，创建一个画笔是非常简单的，在之前的文章中也有过简单的介绍。它有三种创建方法，如下：

```java
// 1.创建一个默认画笔，使用默认的配置
Paint()
// 2.创建一个新画笔，并通过 flags 参数进行配置。
Paint(int flags)
// 3.创建一个新画笔，并复制参数中画笔的设置。
Paint(Paint paint)
```

第1种方式创建默认画笔的方式相信大家都会。

第2种方式如果设置 flags 为 0  创建出来和默认画笔也是相同的，至于 flags 参数可用设置哪些内容，可以参考最上面的常量表格，里面的参数都是可以设置的，如果需要设置多个参数，参数之间用 `|` 进行连接即可。如下：

```java
Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.DITHER_FLAG); 
```

第3种方式是根据已有的画笔复制一个画笔，就是将已有画笔的所有属性都复制到新画笔种，也比较容易理解：

```
Paint paintCopy = new Paint(paint);
```

> 复制后的画笔是一个全新的画笔，对复制后的画笔进行任何修改调整都不会影响到被复制的画笔。

你可以观察下面的测试代码来了解以上的3种创建方式。

```java
Paint paint1 = new Paint();
Log.i(TAG, "paint1 isAntiAlias = " + paint1.isAntiAlias());
Log.i(TAG, "paint1 isDither = " + paint1.isDither());

Paint paint2 = new Paint(Paint.ANTI_ALIAS_FLAG | Paint.DITHER_FLAG);
Log.i(TAG, "paint2 isAntiAlias = " + paint2.isAntiAlias());
Log.i(TAG, "paint2 isDither = " + paint2.isDither());

Paint paint3 = new Paint(paint2);
paint3.setAntiAlias(false);
Log.i(TAG, "paint3 isAntiAlias = " + paint3.isAntiAlias());
Log.i(TAG, "paint3 isDither = " + paint3.isDither());
```

输出结果：

```java
paint1 isAntiAlias = false
paint1 isDither = false
    
paint2 isAntiAlias = true
paint2 isDither = true
    
paint3isAntiAlias = false
paint3 isDither = true
```

画笔在创建之后依旧可以调整，上面的第2种和第3种创建方式，进行的参数设置，在画笔创建完成后依旧可以进行。通过如下的方法：

| 返回值 | 简介                                            |
| ------ | ----------------------------------------------- |
| int           | **getFlags()**<br />获取画笔相关的一些设置(标志)。           |
| void   | **setFlags(int flags)**<br />设置画笔的标志位。 |
| void   | **set(Paint src)**<br />复制 src 的画笔设置。   |
| void   | **reset()**<br />将画笔恢复为默认设置。         |

不过**并不建议使用 setFlags 方法，这是因为 setFlags 方法会覆盖之前设置的内容**，例如：

```java
Paint paint = new Paint();
paint.setFlags(Paint.ANTI_ALIAS_FLAG);
paint.setFlags(Paint.DITHER_FLAG);
Log.i(TAG, "paint isAntiAlias = " + paint.isAntiAlias());
Log.i(TAG, "paint isDither = " + paint.isDither());
```

输出结果：

```java
paint isAntiAlias = false
paint isDither = true
```

> 从结果可以看出，只有最后一次设置的内容有效，之前设置的所有内容都会被覆盖掉。因此不推荐使用。
>
> 如果了解 Google 工程师比较喜欢的编码规范就可以知道原因是什么，最终的flags是由多个flag用"或(`|`)"连接起来的，也就是一个变量，如果直接使用 set 方法，自然是会覆盖掉之前设置的内容的。如果想要调整 flag 个人建议还是使用 paint 提供的一些封装方法，如：`setDither(true)`，而不要自己手动去直接操作 flag。 
>
> 如果有人对 flags 的存储方式感兴趣可以看看这个例子，假如：0x0001 表示类型A， 0x0010 表示类型B，0x0100 表示类型C，0x1000 表示类型D，那么当类型ABD同时存在，但C不存在时时只用存储 0x1011 即可，相比于使用4个 boolean 值来说，这种方案可以显著的节省内存空间的占用，并且用户设置起来也比较方便，可以使用或"\|"同时设置多个类型。当然弊端也是有的，那就是单独更改其中一个参数时时稍微麻烦一点，需要进行一些位运算。

**使用 set(Paint src) 可以复制一个画笔，但需要注意的是，如果调用了这个方法，当前画笔的所有设置都会被覆盖掉，而替换为所选画笔的设置。**

**如果想将画笔重置为初始状态，那就调用 `reset()` 方法，该方法会让画笔的所有设置都还原为初始状态，调用该方法后得到的画笔和刚创建时的状态是一样的。**

### 2.2 画笔颜色

这个是最常用的方法，它相关的方法如下；

| 返回值        | 简介                                                         |
| ------------- | ------------------------------------------------------------ |
| int           | **getAlpha()**<br />只返回颜色的alpha值。                    |
| void          | **setAlpha(int a)**<br />设置透明度。                        |
| int           | **getColor()**<br />返回画笔的颜色。                         |
| void          | **setColor(int color)**<br />设置颜色。                      |
| void          | **setARGB(int a, int r, int g, int b)**<br />设置带透明通道的颜色。 |

Android 中有 1 个透明通道(Alpha)和 3 个色彩通道(RGB)，其中 Alpha 通道可以单独设置。通过 **getAlpha()** 和 **setAlpha(int a)** 方法可以单独调整透明通道，其中 **setAlpha(int a)** 中参数的取值范围是 0 - 255，即对应 16 进制中的 0x00 - 0xFF。

```java
// 下面两种设置方式是等价的，一种是 10 进制，一种是 16 进制
paint1.setAlpha(204);
paint2.setAlpha(0xCC);
```

同理，**setARGB(int a, int r, int g, int b)** 的 4 个参数的取值范围也是 0 - 255，对应 0x00 - 0xFF，下面的设置同样是等价的。

```
paint1.setARGB(204, 255, 255, 0);
paint2.setARGB(0xCC, 0xFF, 0xFF, 0x00);
```

当然，这样设置起来比较麻烦，我们最常用的还是直接使用 **setColor(int color)** 方法，它接受一个 int 类型的参数来表示颜色，我们既可以使用系统内置的一些标准颜色，也可以使用自定义的一些颜色，如下：

```java
paint.setColor(Color.GREEN);
paint.setColor(0xFFE2A588);
```

**注意：**

在使用 setColor 方法时，所设置的颜色必须是 ARGB 同时存在的，通常每个通道用两位16进制数值表示，如 0xFFE2A588。总共 8 位，其中 FF 表示 Alpha 通道。

如果不设置 Alpha 通道，则默认Alpha通道为 0，即完全透明，如：0xE2A588，总共 6 位，没有 Alpha 通道，如果这样设置，则什么颜色也绘制不出来。

同样需要注意的是，setColor 不能直接引用资源，不能这样使用：`paint.setColor(R.color.colorPrimary);` 如果你这样使用了，编译器会报错的。如果想要使用预定义的颜色资源，可以像下面这样调用：

```java
int color = context.getResources().getColor(R.color.colorPrimary);
paint.setColor(color);
```

### 2.4 画笔宽度

画笔宽度，就是画笔的粗细，它通过下面的方式设置。

```java
// 将画笔设置为描边
paint.setStyle(Paint.Style.STROKE);
// 设置线条宽度
paint.setStrokeWidth(120);
```

**注意： 这条线的宽度是同时向两边进行扩展的，例如绘制一个圆时，将其宽度设置为 120 则会向外扩展 60 ，向内缩进 60，如下图所示。**

![paint-width](/assets/customview/paint/paint-stroke-0.png)

**因此如果绘制的内容比较靠近视图边缘，使用了比较粗的描边的情况下，一定要注意和边缘保持一定距离(`边距>StrokeWidth/2`) 以保证内容不会被剪裁掉。**

如下面这种情况，直接绘制一个矩形，如果不考虑画笔宽度，则绘制的内容就可能不正常。

**在一个 1000x1000 大小的画布上绘制与个大小为 500x500 ，宽度为 100 的矩形。**

> 灰色部分为画布大小。    
> 红色为分割线，将画笔分为均等的四份。  
> 蓝色为矩形。  

```java
paint.setStrokeWidth(100);
paint.setColor(0xFF7FC2D8);
Rect rect = new Rect(0, 0, 500, 500);
canvas.drawRect(rect, paint);
```

![paing-stroke-0](/assets/customview/paint/paint-stroke-1.png)

如果考虑到画笔宽度，需要绘制一个大小刚好填充满左上角区域的矩形，那么实际绘制的矩形就要小一些，(**如果只是绘制一个矩形的话，可以将矩形向内缩小画笔宽度的一半**) 这样绘制出来就是符合预期的。

```java
paint.setStrokeWidth(100);
paint.setColor(0xFF7FC2D8);
Rect rect = new Rect(0, 0, 500, 500);
rect.inset(50, 50);     // 注意这里，向内缩小半个宽度
canvas.drawRect(rect, paint);
```

![paing-stroke-1](/assets/customview/paint/paint-stroke-2.png)

> **这里只是用矩形作为例子说明，事实上，绘制任何图形，只要有描边的，就要考虑描边宽度占用的空间，需要适当的缩小图形，以保证其可以完整的显示出来。**
>
> **注意：在实际的自定义 View 中也不要忽略 padding 占用的空间哦。**

#### **hairline mode (发际线模式)：**

在设置画笔宽度的的方法有如下注释：

```
Set the width for stroking.
Pass 0 to stroke in hairline mode.
Hairlines always draws a single pixel independent of the canva's matrix.
```

在画笔宽度为 0 的情况下，使用 drawLine 或者使用描边模式(STROKE)也可以绘制出内容。只是绘制出的内容始终是 1 像素，不受画布缩放的影响。该模式被称为**hairline mode (发际线模式)**。

> 如果你设置了画笔宽度为 1 像素，那么如果画布放大到 2 倍，1 像素会变成 2 像素。但如果是 0 像素，那么不论画布如何缩放，绘制出来的宽度依旧为 1 像素。

```java
// 缩放 5 倍
canvas.scale(5, 5, 500, 500);

// 0 像素 (Hairline Mode)
paint.setStrokeWidth(0);
paint.setColor(0xFF7FC2D8);
canvas.drawCircle(500, 455, 40, paint);

// 1 像素
paint.setStrokeWidth(1);
paint.setColor(0xFF7FC2D8);
canvas.drawCircle(500, 545, 40, paint);
```

可以看到，在放大 5 倍的情况下，1 像素已经变成了 5 像素，但 hairline mode 绘制出来依旧是 1 像素。

![paint-stroke-3](/assets/customview/paint/paint-stroke-3.png)



### 2.3 画笔模式

这里的画笔模式(**Paint.Style**)就是指绘制一个图形时，是绘制边缘轮廓，绘制内容区域还是两者都绘制，它有三种模式。

| Style                       | 简介                                |
| --------------------------- | ----------------------------------- |
| Paint.Style.FILL            | 填充内容，也是画笔的默认模式。      |
| Paint.Style.STROKE          | 描边，只绘制图形轮廓。              |
| Paint.Style.FILL_AND_STROKE | 描边+填充，同时绘制轮廓和填充内容。 |

```java
//填充
mPaint.setStyle(Paint.Style.FILL);
// 描边
mPaint.setStyle(Paint.Style.STROKE);
// 描边+填充
mPaint.setStyle(Paint.Style.FILL_AND_STROKE);
```

**示例程序：**

用一个简单的例子说明一下不同模式的区别。

```java
// 画笔初始设置
Paint paint = new Paint();
paint.setAntiAlias(true);
paint.setStrokeWidth(50);
paint.setColor(0xFF7FC2D8);

// 填充，默认
paint.setStyle(Paint.Style.FILL);
canvas.drawCircle(500, 200, 100, paint);

// 描边
paint.setStyle(Paint.Style.STROKE);
canvas.drawCircle(500, 500, 100, paint);

// 描边 + 填充
paint.setStyle(Paint.Style.FILL_AND_STROKE);
canvas.drawCircle(500, 800, 100, paint);
```

![paint-style](/assets/customview/paint/paint-style.png)

### 2.5 画笔线帽

画笔线帽(**Paint.Cap**)用于指定线段开始和结束时的效果。

```java
// 它通过下面方式设置
paint.setStrokeCap(Paint.Cap.ROUND);
```

Android 中有三种线帽可供选择。

| Cap              | 简介                                               |
| ---------------- | -------------------------------------------------- |
| Paint.Cap.BUTT   | 无线帽，也是默认类型。                             |
| Paint.Cap.SQUARE | 以线条宽度为大小，在开头和结尾分别添加半个正方形。 |
| Paint.Cap.ROUND  | 以线条宽度为直径，在开头和结尾分别添加一个半圆。   |

我们用以下代码来测试线帽。

```java
// 画笔初始设置
Paint paint = new Paint();
paint.setStyle(Paint.Style.STROKE);
paint.setAntiAlias(true);
paint.setStrokeWidth(80);
float pointX = 200;
float lineStartX = 320;
float lineStopX = 800;
float y;

// 默认
y = 200;
canvas.drawPoint(pointX, y, paint);
canvas.drawLine(lineStartX, y, lineStopX, y, paint);

// 无线帽(BUTT)
y = 400;
paint.setStrokeCap(Paint.Cap.BUTT);
canvas.drawPoint(pointX, y, paint);
canvas.drawLine(lineStartX, y, lineStopX, y, paint);

// 方形线帽(SQUARE)
y = 600;
paint.setStrokeCap(Paint.Cap.SQUARE);
canvas.drawPoint(pointX, y, paint);
canvas.drawLine(lineStartX, y, lineStopX, y, paint);

// 圆形线帽(ROUND)
y = 800;
paint.setStrokeCap(Paint.Cap.ROUND);
canvas.drawPoint(pointX, y, paint);
canvas.drawLine(lineStartX, y, lineStopX, y, paint);
```

![paint-cap](/assets/customview/paint/paint-cap.png)

**注意：**

1. 画笔默认是无线帽的，即 BUTT。
2. Cap 也会影响到点的绘制，在 Round 的状态下绘制的点是圆的。
3. 在绘制线条时，线帽时在线段外的，如上图红色部分所显示的内容就是线帽。
4. **上图中红色的线帽是用特殊方式展示出来的，直接绘制的情况下，线帽颜色和线段颜色相同。**

### 2.6 线段连接方式(拐角类型)

画笔的连接方式(**Paint.Join**)是指两条连接起来的线段拐角显示方式。

```java
// 通过下面方式设置连接类型
paint.setStrokeJoin(Paint.Join.ROUND);
```

它同样有三种样式：

| Cap              | 简介            |
| ---------------- | --------------- |
| Paint.Join.MITER | 尖角 (默认模式) |
| Paint.Join.BEVEL | 平角            |
| Paint.Join.ROUND | 圆角            |

![paint-join-1](/assets/customview/paint/paint-join-1.png)

通过效果图可以看出几种不同模式的补偿规则。

### 2.7 斜接模式长度限制

Android 中线段连接方式默认是 MITER，即在拐角处延长外边缘，直到相交位置。

![paint-join-2](/assets/customview/paint/paint-join-2.png)

根据数学原理我们可知，如果夹角足够小，接近于零，那么交点位置就会在延长线上无限远的位置。
**为了避免这种情况，如果连接模式为 MITER(尖角)，当连接角度小于一定程度时会自动将连接模式转换为 BEVEL(平角)。**

那么多大的角度算是比较小呢？根据资料显示，这个角度大约是 28.96°，即 MITER(尖角) 模式下小于该角度的线段连接方式会自动转换为 BEVEL(平角) 模式。

我们可以通过下面的方法来更改默认限制：

```java
// 设置 Miter Limit，参数并不是角度
paint.setStrokeMiter(10);
```

>  **注意：**
>
>  **参数 miter 就是对长度的限制，它可以通过这个公式计算：miter = 1 / sin ( angle / 2 ) ， angel 是两条线的形成的夹角。**
>
>  **其中 miter 的数值应该 >= 0，小于 0 的数值无效，其默认数值是 4，下表是 miter 和角度的一些对应关系。**
>
>  | miter | angle |
>  |:-----:|:-------:|
>  |   10  | 11.48 |
>  |   9	| 12.76 |
>  |   8	| 14.36 |
>  |   7	| 16.43 |
>  |   6	| 19.19 |
>  |   5	| 23.07 |
>  |   4	| 28.96 |
>  |   3	| 38.94 |
>  |   2	| 60    |
>  |   1	| 180   |
>  
> 关于这部分内容可以在 [SkPaint_Reference](https://skia.org/user/api/SkPaint_Reference#Miter_Limit) 查看到。

### 2.8 PathEffect

**PathEffect 在绘制之前修改几何路径，它可以实现划线，自定义填充效果和自定义笔触效果。PathEffect 虽然名字看起来是和 Path 相关的，但实际上它的效果可以作用于 Canvas 的各种绘制，例如 drawLine， drawRect，drawPath 等。**

> **注意： PathEffect  在部分情况下不支持硬件加速，需要关闭硬件加速才能正常使用：**
>
> 1. `Canvas.drawLine()` 和 `Canvas.drawLines()` 方法画直线时，`setPathEffect()` 是不支持硬件加速的；
> 2. `PathDashPathEffect` 对硬件加速的支持也有问题，所以当使用 `PathDashPathEffect` 的时候，最好也把硬件加速关了。

在 Android 中有 6 种 PathEffect，4 种基础效果，2 种叠加效果。

| PathEffect         | 简介                                                   |
| ------------------ | ------------------------------------------------------ |
| CornerPathEffect   | 圆角效果，将尖角替换为圆角。                           |
| DashPathEffect     | 虚线效果，用于各种虚线效果。                           |
| PathDashPathEffect | Path 虚线效果，虚线中的间隔使用 Path 代替。            |
| DiscretePathEffect | 让路径分段随机偏移。                                   |
| SumPathEffect      | 两个 PathEffect 效果组合，同时绘制两种效果。           |
| ComposePathEffect  | 两个 PathEffect 效果叠加，先使用效果1，之后使用效果2。 |

```java
// 通过 setPathEffect 来设置效果
paint.setPathEffect(effect);
```

#### 2.8.1 CornerPathEffect

CornerPathEffect 可以将线段之间的任何锐角替换为指定半径的圆角(适用于 STROKE 或 FILL 样式)。

```java
// radius 为圆角半径大小，半径越大，path 越平滑。
CornerPathEffect(radius);
```



![paint-corner-effect](/assets/customview/paint/paint-corner-effect.png)

**使用 CornerPathEffect，可以实现圆角矩形效果。 但是在一些特殊情况下，它和圆角矩形的显示效果还是稍有不同的，例如下面这种情况：

```java
RectF rect = new RectF(0, 0, 600, 600);
float corner = 300;

// 使用 CornerPathEffect 实现类圆角效果
canvas.translate((1080 - 600) / 2, (1920 / 2 - 600) / 2);
paint.setPathEffect(new CornerPathEffect(corner));
canvas.drawRect(rect, paint);

// 直接绘制圆角矩形
canvas.translate(0, 1920 / 2);
paint.setPathEffect(null);
canvas.drawRoundRect(rect, corner, corner, paint);
```

![paint-corcer-effect-1](/assets/customview/paint/paint-corcer-effect-1.png)

如上图所示，左侧是使用 CornerPathEffect 将矩形的边角变圆润的效果，右侧则是直接绘制圆角矩形的效果。我们知道，在绘制圆角矩形时，如果圆角足够大时，那么绘制出来就会是圆或者椭圆。但是使用 CornerPathEffect 时，不论圆角有多大，它也不会变成圆形或者椭圆。

**CornerPathEffect 也可以让手绘效果更加圆润。**

> 一些简单的绘图场景或者签名场景中，一般使用 Path 来保存用户的手指轨迹，通过连续的 lineTo 来记录用户手指划过的路径，但是直接的 LineTo 会让转角看起来非常生硬，而使用 CornerPathEffect 效果则可以快速的让轨迹圆润起来。

![paint-corcer-effect-2](/assets/customview/paint/paint-corcer-effect-2.gif)

如上图，左侧是未经优化的原始路径，右侧是使用了 CornerPathEffect 效果后的路径。上图测试代码如下：

```java
public class CornerPathEffectTestView extends View {
    Paint mPaint = new Paint();
    PathEffect mPathEffect = new CornerPathEffect(200);
    Path mPath = new Path();

    public CornerPathEffectTestView(Context context) {
        this(context, null);
    }

    public CornerPathEffectTestView(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        mPaint.setStrokeWidth(20);
        mPaint.setStyle(Paint.Style.STROKE);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        switch (event.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                mPath.reset();
                mPath.moveTo(event.getX(), event.getY());
                break;
            case MotionEvent.ACTION_MOVE:
                mPath.lineTo(event.getX(), event.getY());
                break;
            case MotionEvent.ACTION_CANCEL:
            case MotionEvent.ACTION_UP:
                break;
        }
        postInvalidate();
        return true;
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);
        // 绘制原始路径
        canvas.save();
        mPaint.setColor(Color.BLACK);
        mPaint.setPathEffect(null);
        canvas.drawPath(mPath, mPaint);
        canvas.restore();

        // 绘制带有效果的路径
        canvas.save();
        canvas.translate(0, canvas.getHeight() / 2);
        mPaint.setColor(Color.RED);
        mPaint.setPathEffect(mPathEffect);
        canvas.drawPath(mPath, mPaint);
        canvas.restore();
    }
}
```

#### 2.8.2 DashPathEffect

DashPathEffect 用于实现虚线效果(适用于 STROKE 或 FILL_AND_STROKE 样式)。

```java
// intervals：必须为偶数，用于控制显示和隐藏的长度。
// phase：相位。
DashPathEffect(float intervals[], float phase)
```

| 参数        | 简介                                                         |
| ----------- | ------------------------------------------------------------ |
| intervals[] | 间隔，用于控制虚线显示长度和隐藏长度，它必须为偶数(且至少为 2 个)，按照[显示长度，隐藏长度，显示长度，隐藏长度]的顺序来显示。 |
| phase       | 相位(和正余弦函数中的相位类似，周期为intervals长度总和)，也可以简单的理解为偏移量。 |

```java
Path path_dash = new Path();
path_dash.lineTo(0, 1720);

canvas.save();
canvas.translate(980, 100);
paint.setPathEffect(new DashPathEffect(new float[]{200, 100}, 0));
canvas.drawPath(path_dash, paint);
canvas.restore();

canvas.save();
canvas.translate(400, 100);
paint.setPathEffect(new DashPathEffect(new float[]{200, 100}, 100));
canvas.drawPath(path_dash, paint);
canvas.restore();
```

![paint-dash-effect3](/assets/customview/paint/paint-dash-effect3.png)

**如上图所示，虚线效果是根据 intervals[] 中的数值周期显示的，而 phase 则用于控制相位差(偏移量)。**

**注意：intervals[] 中是允许设置多组数据的，每两个为一组，第一个表示显示长度，第二个表示隐藏长度。**

> DashPathEffect 使用起来比较简单，但是也有人拿来玩一些特殊效果，例如这篇文章：[使用DashPathEffect绘制一条动画曲线](http://www.jcodecraeer.com/a/anzhuokaifa/androidkaifa/2015/0907/3429.html)。 不过这篇文章中实现的效果也可以使用 PathMeasure 的截取功能来实现，通过截取不同长度的 Path 来实现动画效果。

#### 2.8.3 PathDashPathEffect

这个也是实现类似虚线效果，只不过这个虚线中显示的部分可以指定为一个 Path(适用于 STROKE 或 FILL_AND_STROKE 样式)。

```java
// shape: Path 图形
// advance: 图形占据长度
// phase: 相位差
// style: 转角样式
PathDashPathEffect(Path shape, float advance, float phase, PathDashPathEffect.Style style);
```

**注意：参数中的 shape 只能是 FILL 模式。**

PathDashPathEffect 允许使用一个 Path 图形作为显示效果，如下：

![paint-pash-dash-effect](/assets/customview/paint/paint-pash-dash-effect.png)

**注意：参数中的shape(Path)只能是 FILL 模式，即便画笔是 STROKE 样式，shape 也只会是 FILL。**

上图中分割线示例代码：

```java
// 画笔初始设置
Paint paint = new Paint();
paint.setStyle(Paint.Style.STROKE);
paint.setAntiAlias(true);

RectF rectF = new RectF(0, 0, 50, 50);

// 方形
Path rectPath = new Path();
rectPath.addRect(rectF, Path.Direction.CW);

// 圆形 椭圆
Path ovalPath = new Path();
ovalPath.addOval(rectF, Path.Direction.CW);

// 子弹形状
Path bulletPath = new Path();
bulletPath.lineTo(rectF.centerX(), rectF.top);
bulletPath.addArc(rectF, -90, 180);
bulletPath.lineTo(rectF.left, rectF.bottom);
bulletPath.lineTo(rectF.left, rectF.top);

// 星星形状
PathMeasure pathMeasure = new PathMeasure(ovalPath, false);
float length = pathMeasure.getLength();
float split = length / 5;
float[] starPos = new float[10];
float[] pos = new float[2];
float[] tan = new float[2];
for (int i = 0; i < 5; i++) {
    pathMeasure.getPosTan(split * i, pos, tan);
    starPos[i * 2 + 0] = pos[0];
    starPos[i * 2 + 1] = pos[1];
}
Path starPath = new Path();
starPath.moveTo(starPos[0], starPos[1]);
starPath.lineTo(starPos[4], starPos[5]);
starPath.lineTo(starPos[8], starPos[9]);
starPath.lineTo(starPos[2], starPos[3]);
starPath.lineTo(starPos[6], starPos[7]);
starPath.lineTo(starPos[0], starPos[1]);
Matrix matrix = new Matrix();
matrix.postRotate(-90, rectF.centerX(), rectF.centerY());
starPath.transform(matrix);


canvas.translate(360, 100);
// 绘制分割线 - 方形
canvas.translate(0, 100);
paint.setPathEffect(new PathDashPathEffect(rectPath, rectF.width() * 1.5f, 0, PathDashPathEffect.Style.TRANSLATE));
canvas.drawLine(0, 0, 1200, 0, paint);

// 绘制分割线 - 圆形
canvas.translate(0, 100);
paint.setPathEffect(new PathDashPathEffect(ovalPath, rectF.width() * 1.5f, 0, PathDashPathEffect.Style.TRANSLATE));
canvas.drawLine(0, 0, 1200, 0, paint);

// 绘制分割线 - 子弹型
canvas.translate(0, 100);
paint.setPathEffect(new PathDashPathEffect(bulletPath, rectF.width() * 1.5f, 0, PathDashPathEffect.Style.TRANSLATE));
canvas.drawLine(0, 0, 1200, 0, paint);

// 绘制分割线 - 星型
canvas.translate(0, 100);
paint.setPathEffect(new PathDashPathEffect(starPath, rectF.width() * 1.5f, 0, PathDashPathEffect.Style.TRANSLATE));
canvas.drawLine(0, 0, 1200, 0, paint);
```

**PathDashPathEffect.Style**

PathDashPathEffect 的最后一个参数是 PathDashPathEffect.Style，这个参数用于处理 Path 图形在转角处的样式。

| Style     | 简介                 |
| --------- | -------------------- |
| TRANSLATE | 在转角处对图形平移。 |
| ROTATE    | 在转角处对图形旋转。 |
| MORPH     | 在转角处对图形变形。 |

![paint-pash-dash-effect3](/assets/customview/paint/paint-pash-dash-effect3.png)

#### 2.8.4 DiscretePathEffect

DiscretePathEffect 可以让 Path 产生随机偏移效果。

```java
// segmentLength: 分段长度
// deviation: 偏移距离
DiscretePathEffect(float segmentLength, float deviation);
```

![paint-discrete-effect](/assets/customview/paint/paint-discrete-effect.png)

> 至今尚未见过这种效果的应用场景。

#### 2.8.5 SumPathEffect

SumPathEffect 用于合并两种效果，它相当于两种效果都绘制一遍。

```java
// 两种效果相加
SumPathEffect(PathEffect first, PathEffect second);
```



![paint-sum-effect-0349877](/assets/customview/paint/paint-sum-effect-0349877.png)

#### 2.8.6 ComposePathEffect

ComposePathEffect 也是合并两种效果，只不过先应用一种效果后，再次叠加另一种效果，因此**交换参数最终得到的效果是不同的**。

```java
// 构造一个 PathEffect, 其效果是首先应用 innerpe 再应用 outerpe (如: outer(inner(path)))。
ComposePathEffect(PathEffect outerpe, PathEffect innerpe);
```

![paint-compose-effect](/assets/customview/paint/paint-compose-effect.png)

### 2.9 getFillPath

```java
// 根据原始Path(src)获取预处理后的Path(dst)
paint.getFillPath(Path src, Path dst);
```

在 PathEffect 一开始有这样一句介绍：“**PathEffect 在绘制之前修改几何路径**... ” 这句话表示的意思是，我们在绘制内容时，会在绘制之前对这些内容进行处理，最终进行绘制的内容实际上是经过处理的，而不是原始的。

事实上，我们所有绘制的图形，包括线条，矩形，Path 等内容，由于存在线条宽度，填充模式，线帽等不同的设置，在绘制之前都是需要进行预处理的。

**Q: 我们能不能拿到预处理后的图形呢？**

A: 答案是可以的，但是我们只能拿到 Path 预处理后的内容。

![paint-getfillpath](/assets/customview/paint/paint-getfillpath.png)

如上图，我们使用一个圆弧形状的 Path，设置画笔为描边，绘制出来就是第一个图形的效果。

```java
Path arcPath = new Path();
arcPath.addArc(new RectF(100, 100, 500, 500), 30, 300);

Paint paint = new Paint();
paint.setStyle(Paint.Style.STROKE);
canvas.drawPath(arcPath, paint);
```

将画笔设置为描边模式，较粗的描边效果，线帽效果为 Round 后绘制出来就是第二个图形的效果。

```java
Paint paint = new Paint();
paint.setStyle(Paint.Style.STROKE);
paint.setStrokeCap(Paint.Cap.ROUND);
paint.setStrokeWidth(100);

canvas.drawPath(arcPath, paint);
```

如果通过 paint 的 getFillPath 获取处理后的 Path，然后绘制出来就是第三种图形的样式。

```java
Path borderPath = new Path();
paint.getFillPath(arcPath, borderPath);	// getFillPath

// 测试画笔，注意设置为 STROKE
Paint testPaint = new Paint();
testPaint.setStyle(Paint.Style.STROKE);
testPaint.setStrokeWidth(2);
testPaint.setAntiAlias(true);
// 绘制通过 getFillPath 获取到的 Path
canvas.drawPath(borderPath, testPaint);
```

**Q: 可是我们拿到预处理后的 Path 有什么作用呢？**

A: 尽管通常情况下我们用不到，但在一些特殊情况下还是有些作用的，可以通过下面的一个实例了解。

在我前段时间开源的一个库里面，需要实现下面这样的效果，一个弧形的 SeekBbar。

![arcseekbar-shadow](/assets/customview/paint/arcseekbar-shadow.gif)

如上图，是一个非常粗的圆弧，有一个白色的描边，这个白色的描边效果就可以通过 getFillPath 轻松实现。

```java
// 通过 getFillPath 来获得圆弧的实际区域, 存储到 mBorderPath 中
mArcPaint.getFillPath(mSeekPath, mBorderPath);
```

直接用 getFillPath 获取到这个粗圆弧的边缘，存储到 mBorderPath 中，把 mBorderPath 用白色画笔绘制出来就可以实现上图中的描边效果啦。

并且，用户的点击事件也需要进行一些限制，只有用户点击到圆弧上的时候才能触发进度变化，而点击其余部分则不处理，这里可以利用 getFillPath 和 Region 来实现点击区域限定。

**关于使用 Region 判断点击区域可以参考 ：[特殊控件的事件处理方案](http://www.gcssloop.com/customview/touch-matrix-region)**

```java
Path mSeekPath = ...	// 圆弧 Path。
Path mBorderPath = ...	// 圆弧 Path 的边缘。
Paint mArcPaint = ...	// 画笔，设置好 Style，Cap, StrokeWidth。
Region mArcRegion = ...	// 用户点击区域

// 通过 getFillPath 来获得圆弧的实际区域, 存储到 mBorderPath 中
mArcPaint.getFillPath(mSeekPath, mBorderPath);
// 将实际区域赋值给 Region
mArcRegion.setPath(mBorderPath, new Region(0, 0, w, h));

// 使用 Region 判断点击是否处于 Region 区域中
mArcRegion.contains(x, y);
```

**更多的细节可以去开源库 [ArcSeekBar](https://github.com/GcsSloop/arc-seekbar) 中查看。**

**ArcSeekBar: [https://github.com/GcsSloop/arc-seekbar](https://github.com/GcsSloop/arc-seekbar)**

## 3. 结语

在 Android 绘图之中，Paint 是相当重要的组成部分，由于 Paint 内容十分繁杂，本文也只能介绍其中一部分内容，关于画笔图像优化，叠加模式，文本处理等相关内容会放到后续的文章中进行介绍。

## About Me

### 作者微博: <a href="http://weibo.com/GcsSloop" target="_blank">@GcsSloop</a>

<a href="http://www.gcssloop.com/info/about" target="_blank"><img src="http://gcsblog.oss-cn-shanghai.aliyuncs.com/blog/gcs_banner.jpg?gcssloop" width="300" style="display:inline;" /></a>

## 参考文章

- [Android · Paint](https://developer.android.com/reference/android/graphics/Paint)
- [HenCoder: 自定义 View 1-2 Paint 详解](https://hencoder.com/ui-1-2/)
- [SkPaint_Reference](https://skia.org/user/api/SkPaint_Reference)
- [Android Recipe #4, path tracing](http://www.curious-creature.com/2013/12/21/android-recipe-4-path-tracing/)
- [A better underline for Android](https://medium.com/androiddevelopers/a-better-underline-for-android-90ba3a2e4fb)