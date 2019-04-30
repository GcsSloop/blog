---
layout: post
category: GeBug
title: 雕虫晓技(五) 网格分页布局源码解析(上)
tags: Android
keywords: Android
excerpt: 网格分页布局的实现原理、基础细节和一些实现技巧。
relink: https://xiaozhuanlan.com/topic/5841730926
typora-root-url: ../../../Source
---

### 关于作者

GcsSloop，一名 2.5 次元魔法师。  
[微博](http://weibo.com/GcsSloop/home) | [GitHub](https://github.com/GcsSloop) | [博客](http://www.gcssloop.com/)

## 0.前言

**pager-layoutmanager： [https://github.com/GcsSloop/pager-layoutmanager](https://github.com/GcsSloop/pager-layoutmanager)**

这个是我之前公开分享的一个开源库 [【PagerLayoutManager(网格分页布局)】](https://github.com/GcsSloop/pager-layoutmanager) 的详细解析，在开始讲解之前，先看看它能实现的一些效果。

![emo](/assets/gebug/05-pager-layoutmanager/demo1.gif) ![emo](/assets/gebug/05-pager-layoutmanager/demo2.gif)

上面是它的应用场景之一，再看一下实现这种场景所需的代码：

```java
// 布局管理器
PagerGridLayoutManager layoutManager = new PagerGridLayoutManager(1, 4, PagerGridLayoutManager.HORIZONTAL);
mRecyclerView.setLayoutManager(layoutManager);

// 滚动辅助器
PagerGridSnapHelper snapHelper = new PagerGridSnapHelper();
snapHelper.attachToRecyclerView(mRecyclerView);
```

没错，想要实现这样分页滚动的效果，只需要四五行代码就可以了，至于 RecyclerView 和 Adapter 使用官方提供的即可。

## 1. 摘要

之前项目中有类似的需求，在网上寻找了一些实现方案，结果均不太满意。

有些方案使用起来过于麻烦，例如 ViewPager + GridView，不用我说，用过的都知道，这种方案数据绑定十分麻烦，并且会多一层View嵌套，相对来说会损耗一些性能。

有些则是存在重大缺陷，例如内存泄露，性能问题等，像上面那种场景仅展示几个固定条目的情况还不明显，但是当需要动态加载几百个条目的时候缺陷就显现出来了，会造成严重的滑动卡顿，当数据达到一定数量级的时候，可能直接导致ANR。

在试过诸多方案，踩过很多坑以后，依旧没有找到合适的方案，于是自己动手，丰衣足食，也就有了这个项目。

这个项目已经在公司多个项目上使用，经过十几个版本的迭代更新，基本上已经没有重大bug了，更新日志可以见这里： [PagerLayoutManager](https://github.com/GcsSloop/pager-layoutmanager)。

如果你只是需要这样一个组件，那么直接点击上面的链接，看它的说明文档就可以了，本文不是你需要的，但如果你想要知道它的具体实现方案，对它进行改进的话，那么下文的内容可能会对你有所帮助。

## 2. 基础网格布局解析

### 2.1 方案选择

首先项目所需要的核心内容主要有以下几点：

1. 网格效果
2. 分页显示
3. 横向排布

![demo3](/assets/gebug/05-pager-layoutmanager/demo3.jpg)

所需效果大概就如上图所示，为了避免重复造轮子，在一开始我想要使用一些现有的组件来完成。

1. 最先想到的自然是网格布局，但是呢，项目需要动态加载数百条的数据，网格布局本身不带有条目自动回收创建功能，如果同让上百个View存在于一个页面之中，不卡爆才怪。

2. 之后想到的是 ViewPager+GridLayout，但是这种方案数据拆分和绑定十分麻烦，遂放弃。

3. 然后想 RecyclerView + GridLayoutManager 看起来靠谱一点，首先使用 GridLayoutMnager，作出网格效果，然后监听滚动事件来控制滚动距离，一切看起来都是那么美好，但是，事实证明这种方案还是太难使用。

   首先网格布局同时只能控制行数或者列数其中一个，如果想要如果想要像设定那样2行3列，一页整好现实6条数据，那么View的宽高是需要动态计算的，如果设置了固定大小，必然会导致适配问题，

   其次，数据不一定是整页，如果是2行3列，一页6条数据，那么使用 GridLayoutManager滑动后可能会出现这样的效果，另外，数据排列顺序也并非我所需要的：

   ![demo4](/assets/gebug/05-pager-layoutmanager/demo4.jpg)

   这显然不是我想要的效果，在数据不足一页时，我需要的效果是这样的：

   ![demo5](/assets/gebug/05-pager-layoutmanager/demo5.jpg)

   如果想要在不动 GridLayoutManager 的情况下实现需求，则需要执行如下操作：

   假设，需要显示2行3列，共8条数据，那么需要执行如下操作：

   1. 将不足一页部分补足一页

      ```
      1、2、3、4、5、6、7、8
      1、2、3、4、5、6、7、8、空、空、空、空
      ```

   2. 通过数据变换调整数据次序使其显示符合预期

      ```
      1、2、3、4、5、6、7、8、空、空、空、空
      1、4、2、5、3、6、7、空、8、空、空、空
      ```

   3. 通过监听滚动控制滚动距离来实现分页显示

   另外，页面数据是分页加载显示的，如果使用上面这种方案，单是数据处理逻辑就能把我绕进去。

**在经过深思熟虑之后，我决定自定义一个 LayoutManager 来实现这个“简单”的需求。**幸好 RecyclerView 的扩展性非常强，自定义一个 LayoutManager 也不是什么难事，下面我们就一步步的的实现一个分页网格布局。

### 2.2 创建一个基础的 LayoutManager

首先我们创建一个 PagerGridLayoutManager 并继承 RecyclerView.LayoutManager，实现其抽象方法，一个LayoutManager 就可以用了，如下：

```java
public class PagerGridLayoutManager extends RecyclerView.LayoutManager {
    @Override
    public RecyclerView.LayoutParams generateDefaultLayoutParams() {
        return new RecyclerView.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT);
    }
}
```

这是一个符合规范的 LayoutManager，但是目前它不会将任何View显示在界面上，因为它没有对条目进行处理，也就意味着没有条目会添加到界面上。但我们先不着急处理子条目，在真正布局之前，我们先来解决一些简单的基础问题。

### 2.3 确定行列数数和滚动方向

由于行列数会直接关系到一个页面显示条目的个数，进而影响到总共可以滚动的j距离和页数总数，所以它们要在构造方法中设置。

而滚动方向一般都是确定的，横向或者竖向，并且基本不变，所以，它也可以在构造方法中进行设置，提醒使用者不要忘记滚动方向。

所以为 PagerGridLayoutManager 添加如下的属性和构造方法：

```Java
public static final int VERTICAL = 0;           // 垂直滚动
public static final int HORIZONTAL = 1;         // 水平滚动

@IntDef({VERTICAL, HORIZONTAL})
public @interface OrientationType {}            // 滚动类型

@OrientationType
private int mOrientation = HORIZONTAL;          // 默认水平滚动

private int mRows = 0;                          // 行数
private int mColumns = 0;                       // 列数
private int mOnePageSize = 0;                   // 一页的条目数量

/**
 * 构造函数
 *
 * @param rows        行数
 * @param columns     列数
 * @param orientation 方向
 */
public PagerGridLayoutManager(@IntRange(from = 1, to = 100) int rows,
                              @IntRange(from = 1, to = 100) int columns,
                              @OrientationType int orientation) {
    mOrientation = orientation;
    mRows = rows;
    mColumns = columns;
    mOnePageSize = mRows * mColumns;
}
```

注意：

1. 上面使用了 @IntDef 注解自定义了一个 OrientationType 注解，用于防治用户随意设置数值。
2. 使用 @IntRange 方法将行列数限制在一个较合理的范围内。
3. 在初始化的时候利用行列数计算出了一页应该有多少个条目，方面后面使用。

在确定了滚动方向后，顺便就可以实现 LayoutManager 以下两个方法了，这两个方法会真正的决定 RecyclerView 可以滚动的方向。

```java
/** 是否可以水平滚动
 * @return true 是，false 不是。
 */
@Override
public boolean canScrollHorizontally() {
    return mOrientation == HORIZONTAL;
}

/** 是否可以垂直滚动
 * @return true 是，false 不是。
 */
@Override
public boolean canScrollVertically() {
    return mOrientation == VERTICAL;
}
```

### 2.4 计算子条目的宽高

由于我们是分页网格显示，目前已经知道了行列数，如果再知道 RecyclerView 的宽高，就能算出单个自条目的所能占用的宽高了。

因此我们再添加两个方法用于获取 RecyclerView 的可用宽高：

```Java
/** 获取可用的宽度
 * @return 宽度 - padding
 */
private int getUsableWidth() {
    return getWidth() - getPaddingLeft() - getPaddingRight();
}

/** 获取可用的高度
 * @return 高度 - padding
 */
private int getUsableHeight() {
    return getHeight() - getPaddingTop() - getPaddingBottom();
}
```

注意：可用宽高要减去 Padding 数值。

有了总的可用宽高，在分别处以行列数就可以得到每一个子条目占用的宽高了。

```Java
private int mItemWidth = 0;  // 条目宽度
private int mItemHeight = 0; // 条目高度
mItemWidth = getUsableWidth() / mColumns;
mItemHeight = getUsableHeight() / mRows;
```

### 2.5 计算条目显示区域

既然知道了条目的宽高，那么只要知道这个条目所在位置就能确切的知道它的显示区域了。

这里使用的计算方案是：**条目所在页面的偏移量 + 条目在页面内的偏移量**。  
同时由于页面可能会反复的滑动，因此不可能每次滚动时都重新计算一下条目的位置，因此计算过的条目用 `mItemFrames` 存储起来，之后想要获取该条目的显示区域，直接从 `mItemFrames` 中取出即可，防止重复计算造成的性能浪费。至于存储所耗费的内存空间，其实并不算大，存储 10 万个 Rect 耗费内存也才 4M 左右，正常情况下一般不会超过一万条数据，所耗费的空间一般不会超过 0.5M，大可以放心使用。

```Java
private SparseArray<Rect> mItemFrames;  // 条目的显示区域

/** 获取条目显示区域
 * @param pos 位置下标
 * @return 显示区域
 */
private Rect getItemFrameByPosition(int pos) {
    Rect rect = mItemFrames.get(pos);
    if (null == rect) {
        rect = new Rect();
        // 计算显示区域 Rect
        // 1. 获取当前View所在页数
        int page = pos / mOnePageSize;

        // 2. 计算当前页数左上角的总偏移量
        int offsetX = 0;
        int offsetY = 0;
        if (canScrollHorizontally()) {
            offsetX += getUsableWidth() * page;
        } else {
            offsetY += getUsableHeight() * page;
        }

        // 3. 根据在当前页面中的位置确定具体偏移量
        int pagePos = pos % mOnePageSize;       // 在当前页面中是第几个
        int row = pagePos / mColumns;           // 获取所在行
        int col = pagePos - (row * mColumns);   // 获取所在列

        offsetX += col * mItemWidth;
        offsetY += row * mItemHeight;

        rect.left = offsetX;
        rect.top = offsetY;
        rect.right = offsetX + mItemWidth;
        rect.bottom = offsetY + mItemHeight;

        // 存储
        mItemFrames.put(pos, rect);
    }
    return rect;
}
```

### 2.6 布局 ChildView

在进行完上面几步操作添加了这些基础方法后后，这个 PagerGridLayoutManager 实际上还是没法使用的，因为它依旧没有将子条目添加的屏幕上，因此屏幕上什么也不会有。

> 如果熟悉 ViewGroup 的人可能会知道，要控制 ChildView 在 ParentView 中的位置，需要在 ParentView 的 onLayout 方法中调整 ChildView 的具体摆放位置和大小。其实 LayoutManager 和 ViewGroup 的布局是有些类似的，需要在 LayoutManager 的 onLayoutChildren 方法中控制 ChildView 的大小和显示位置。

那么具体如何将子条目添加的屏幕上呢，像下面这样就可以：

```java
public void onLayoutChildren(RecyclerView.Recycler recycler, RecyclerView.State state) {
    int i = 0;
    // 获取第 0 个条目，如果不存在的话 RecyclerView 会自动创建
    View child = recycler.getViewForPosition(i);	
    // 获取该条目的具体应该显示位置
    Rect rect = getItemFrameByPosition(i);
    // 将该条目添加的界面上
    addView(child);
    // 测量该条目，注意 mWidthUsed = 总可用宽度-其余条目占用的宽度， mHeightUsed = 总可用高度-其余条目占用高度
    measureChildWithMargins(child, mWidthUsed, mHeightUsed);
    // 获取布局参数 LayoutParams
    RecyclerView.LayoutParams lp = (RecyclerView.LayoutParams) child.getLayoutParams();
    // 使用 layoutDecorated 确定具体显示位置，注意 margin 数值的处理(此处代码不完整，非最终代码)
    layoutDecorated(child,
            rect.left + lp.leftMargin,
            rect.top + lp.topMargin,
            rect.right - lp.rightMargin,
            rect.bottom - lp.bottomMargin);
}
```

这样子就可以将第 0 个 ViewView 添加到页面上了，鹅妹子嘤！但是这样子只能添加一个 View 如果有很多个 View 需要显示怎么办呢？第一反应自然是循环大法：

```java
for(int i = 0; i < getItemCount(); i++){
    // 省略添加View的代码
}
```

哈哈，似乎一切都很完美，**稍等，似乎有点不对，话说 RecyclerView 最强大的不是条目的回收和复用吗？它是自动进行回收和复用的吗？**

这个自然不是，一个条目是否需要被添加到缓存池或者销毁，是由 LayoutManager 进行控制的，而上面这段代码并没有回收复用条目相关的代码，这显然是不正确的。不仅如此，上面这段代码会将所有的条目都转化为 View 放到页面上，假如只有几个条目还可以，若是存在几百上千个条目，就上面这一个 for 循环一下子就能把内存耗尽，因此这种写法是万万不可的。

一个 RecyclerView 可以有很多的条目，但设备屏幕大小是有限的，所以显示在屏幕上的 View 数量始终是有限的，因此我们将当前显示在屏幕上的 View 显示出来，超出显示区域的 View 则放入缓冲区或者销毁掉。因此我们要知道当前哪些 View 应该被显示，哪些应该被销毁。

首先我们要知道当前的总偏移量，根据偏移量和 RecyclerView 的大小来计算出显示区域，之后将显示区域外的 View 移除掉，显示区域内的 View 添加到当前的界面上。

#### 2.6.1 计算偏移量

在计算和更新偏移量时注意最大可以用偏移量，防止越界。

```java
private int mOffsetX = 0;                       // 水平滚动距离(偏移量)
private int mOffsetY = 0;                       // 垂直滚动距离(偏移量)
private int mMaxScrollX;                        // 最大允许滑动的宽度
private int mMaxScrollY;                        // 最大允许滑动的高度


// 在 onLayoutChildren 时计算可以滚动的最大数值，并对滚动距离进行修正
if (canScrollHorizontally()) {
    mMaxScrollX = (mPageCount - 1) * getUsableWidth();
    mMaxScrollY = getUsableHeight();
    if (mOffsetX > mMaxScrollX) {
        mOffsetX = mMaxScrollX;
    }
} else {
    mMaxScrollX = getUsableWidth();
    mMaxScrollY = (mPageCount - 1) * getUsableHeight();
    if (mOffsetY > mMaxScrollY) {
        mOffsetY = mMaxScrollY;
    }
}


// 更新偏移量
@Override
public int scrollHorizontallyBy(int dx, RecyclerView.Recycler recycler, RecyclerView.State
        state) {
    int newX = mOffsetX + dx;
    int result = dx;
    if (newX > mMaxScrollX) {
        result = mMaxScrollX - mOffsetX;
    } else if (newX < 0) {
        result = 0 - mOffsetX;
    }
    mOffsetX += result;
    setPageIndex(getPageIndexByOffset(), true);
    offsetChildrenHorizontal(-result);
    return result;
}

@Override
public int scrollVerticallyBy(int dy, RecyclerView.Recycler recycler, RecyclerView.State
        state) {
    int newY = mOffsetY + dy;
    int result = dy;
    if (newY > mMaxScrollY) {
        result = mMaxScrollY - mOffsetY;
    } else if (newY < 0) {
        result = 0 - mOffsetY;
    }
    mOffsetY += result;
    offsetChildrenVertical(-result);
    return result;
}
```

#### 2.6.2 计算显示区域

根据 offset 和 view 的大小计算当前实际的显示区域，有了显示区域就能知道哪些条目应该显示在当前界面上。

```java
Rect displayRect = new Rect(
    getPaddingLeft() + mOffsetX,
    getPaddingTop() + mOffsetY,
    getWidth() - getPaddingLeft() - getPaddingRight() + mOffsetX,
    getHeight() - getPaddingTop() - getPaddingBottom() + mOffsetY);
```

#### 2.6.3 判断哪些条目应该被更新

这个判断自然也是有些技巧的，如果是像前面那样，每一次更新都直接一个 for 循环判断所有的条目是否应该显示，那么当条目数量上千时，滑动肯定会卡爆，因为每一次滑动都会导致多次界面的刷新，如果每一次刷新都直接一个 for 循环循环上千次，那么一次滑动循环体执行次数就可能有上万次了，卡顿那才奇怪呢。

所以我们这里使用这样的策略：

1. 刷新前将所有的 View 都移除放到缓冲区
2. 计算当前显示区域的页面是哪个
3. 只刷新与之临近页面的 View

这样不论总共有多少个条目，我们每一次刷新都只会更新几个到几十个条目，会节省大量到时间。

```java
// 1.移除所有View
detachAndScrapAttachedViews(recycler); 

// 2.根据偏移量来计算当前页面和临近页面，计算出这些页面的开始和结束位置
int startPos = 0;
int pageIndex = getPageIndexByOffset();
startPos = pageIndex * mOnePageSize;
Logi("startPos = " + startPos);
startPos = startPos - mOnePageSize * 2;
if (startPos < 0) {
    startPos = 0;
}
int stopPos = startPos + mOnePageSize * 4;
if (stopPos > getItemCount()) {
    stopPos = getItemCount();
}

// 3.针对这些 View 添加到屏幕上或者移除
for (int i = startPos; i < stopPos; i++) {
    // 添加或者移除
    addOrRemove(recycler, displayRect, i);
}
```

**注意：如果你去看项目的源码会看到下面这样的逻辑：**

```java
if (isStart) {
    for (int i = startPos; i < stopPos; i++) {
        addOrRemove(recycler, displayRect, i);
    }
} else {
    for (int i = stopPos - 1; i >= startPos; i--) {
        addOrRemove(recycler, displayRect, i);
    }
}
```

大家可能会奇怪，为啥会有这样的迷之逻辑呢？一个 For 循环居然还要区分正反。  
实际上这是为了控制条目移除和添加的顺序，要先移除再添加，这样会移除的 View 会被先放到缓冲区中，再添加 View 时就可以直接从缓冲区中把被移除的条目直接取出来使用了，而不用重新创建，以减少开销。如果不控制顺序的话，先执行添加操作，由于缓冲区中没有可以使用的 View，会进行先创建，之后再添加到界面上，最后执行移除操作会导致有大量的 View 滞留在缓冲区中，会造成严重的性能浪费。

#### 2.6.4 添加或者移除条目

如果条目的显示区域和当前显示区域有重叠部分(有交集)，就将 View 添加到界面上，否则就将 View 移除。

```java
private void addOrRemove(RecyclerView.Recycler recycler, Rect displayRect, int i) {
    View child = recycler.getViewForPosition(i);
    Rect rect = getItemFrameByPosition(i);	// 获得当前条目显示区域
    // 判断条目显示区域和当前显示区域是否有重叠，如果有重叠就添加，没有就移除
    if (!Rect.intersects(displayRect, rect)) {
        removeAndRecycleView(child, recycler);   // 回收入暂存区
    } else {
        addView(child);
        measureChildWithMargins(child, mWidthUsed, mHeightUsed);
        RecyclerView.LayoutParams lp = (RecyclerView.LayoutParams) child.getLayoutParams();
        layoutDecorated(child,
                rect.left - mOffsetX + lp.leftMargin,
                rect.top - mOffsetY + lp.topMargin,
                rect.right - mOffsetX - lp.rightMargin,
                rect.bottom - mOffsetY - lp.bottomMargin);
    }
}
```

经过上面几步操作，一个最基础的网格布局就完成啦，但是请注意的是，为了比较清晰的表达出核心逻辑，上面的部分代码移除了一部相对无关紧要的逻辑，因此并非最终的代码，最终代码请参考 [【GitHub · pager-layoutmanager 】](https://github.com/GcsSloop/pager-layoutmanager)。

## 3. 结语

在本篇中，只是讲解了有关网格布局相关的知识，此处假设大家已经了解了 RecyclerView 中自定义 LayoutManager 的基础内容，如果不太了解的话，可以先去搜索了解一下基础的知识。另外，关于分页对齐等相关内容会在后续的文章中给大家介绍。

**pager-layoutmanager： [https://github.com/GcsSloop/pager-layoutmanager](https://github.com/GcsSloop/pager-layoutmanager)**

如果喜欢本文的话，欢迎点赞、分享或者打赏支持。

#### **关于作者**

GcsSloop，一名 2.5 次元魔法师。



