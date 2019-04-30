---
layout: post
category: GeBug
title: 雕虫晓技(六) 网格分页布局源码解析(下)
tags: Android
keywords: Android
excerpt: 网格分页布局的实现原理、基础细节和一些实现技巧。
relink: https://xiaozhuanlan.com/topic/1456397082
typora-root-url: ../../../Source
---

## 0. 前言

**pager-layoutmanager： [https://github.com/GcsSloop/pager-layoutmanager](https://github.com/GcsSloop/pager-layoutmanager)**

在[网格分页布局源码解析(上)](https://xiaozhuanlan.com/topic/5841730926)中，主要分享了如何定义一个网格布局，正常运行的效果看起来其实和 GridLayoutManager 有些类似。

这是它的下篇，主要讲解如何让它滑动时一页一页的滚动，而不是随意的滚动，除此之外，还包括一些其他相关内容，例如滚动、平滑滚动和超长距离滚动需要注意的一些细节。



## 1. 分页对齐

**在开始讲解前，先看一下启用了分页对齐和未启用分页对齐的效果有何不同：**

![pic_01](/assets/gebug/06-pager-layoutmanager/pic_01.gif)  ![pic_02](/assets/gebug/06-pager-layoutmanager/pic_02.gif)

**在左侧未启用分页对齐时，滚动到哪里就会停在哪里。在右侧启用了分页对齐后，滚动距离较小时，会回弹到当前页，滚动距离超过阀值时，会自动滚动到下一页。**

让其页面对齐的方法有很多种，其核心就是控制滚动距离，在本文中，我们使用 RecyclerView 官方提供的条目对齐方式，借助 SnapHelper 来进行页面对齐。

### 1.1 SnapHelper

SnapHelper 是官方提供的一个辅助类，主要用于拓展 RecyclerView，让 RecyclerView 在滚动结束时不会停留在任意位置，而是根据一定的规则来约束停留的位置，例如：卡片布局在停止滚动时始终保证一张卡片居中显示，而不是出现两张卡片都显示一半这种情况。  

![pic_03](/assets/gebug/06-pager-layoutmanager/pic_03.jpg)

有关 SnapHelper 的更多内容可以参考：[让你明明白白的使用RecyclerView——SnapHelper详解](https://www.jianshu.com/p/e54db232df62)

官方提供了两个 SnapHelper 的实例，分别是 LinearSnapHelper 和 PagerSnapHelper，不过这两个都不太符合我们的需求，因此我们要自定义一个 SnapHelper 来协助我们完成分页对齐。

### 1.2 让 LayoutManager 支持 SnapHelper

SnapHelper 会尝试处理 Fling，但为了正常工作，LayoutManager 必须实现RecyclerView.SmoothScroller.ScrollVectorProvider 接口，或者重写 onFling(int，int) 并手动处理 Fling。

> Fling: 手指从屏幕上快速划过，手指离开屏幕后，界面由于“惯性”依旧会滚动一段时间，这个过程称为 Fling。Fling 从手指离开屏幕时触发，滚动停止时结束。

我们先让 LayoutManager 实现该接口。

```java
public class PagerGridLayoutManager extends RecyclerView.LayoutManager
        implements RecyclerView.SmoothScroller.ScrollVectorProvider {
    /**
     * 计算到目标位置需要滚动的距离{@link RecyclerView.SmoothScroller.ScrollVectorProvider}
     * @param targetPosition 目标控件
     * @return 需要滚动的距离
     */
    @Override
    public PointF computeScrollVectorForPosition(int targetPosition) {
    	PointF vector = new PointF();
        int[] pos = getSnapOffset(targetPosition);
        vector.x = pos[0];
        vector.y = pos[1];
        return vector;
    }
    
    //--- 下面两个方法是自定义的辅助方法 ------------------------------------------------------
    
    /**
     * 获取偏移量(为PagerGridSnapHelper准备)
     * 用于分页滚动，确定需要滚动的距离。
     * {@link PagerGridSnapHelper}
     *
     * @param targetPosition 条目下标
     */
    int[] getSnapOffset(int targetPosition) {
        int[] offset = new int[2];
        int[] pos = getPageLeftTopByPosition(targetPosition);
        offset[0] = pos[0] - mOffsetX;
        offset[1] = pos[1] - mOffsetY;
        return offset;
    }

    /**
     * 根据条目下标获取该条目所在页面的左上角位置
     *
     * @param pos 条目下标
     * @return 左上角位置
     */
    private int[] getPageLeftTopByPosition(int pos) {
        int[] leftTop = new int[2];
        int page = getPageIndexByPos(pos);
        if (canScrollHorizontally()) {
            leftTop[0] = page * getUsableWidth();
            leftTop[1] = 0;
        } else {
            leftTop[0] = 0;
            leftTop[1] = page * getUsableHeight();
        }
        return leftTop;
    }
    
    // 省略其它部分代码...
}
```

注意：由于我们是分页对齐，所以，最终滚动停留的位置始终应该以页面为基准，而不是以具体条目为基准，所以，我们要计算出目标条目所在页面的坐标，并以此为基准计算出所需滚动的距离。

当然，除了 Fling 操作，我们在用户普通滑动结束时也要进行一次页面对齐，为了支持这一功能，我们在 PagerGridLayoutManager 再定义一个方法，用于寻找当前应该对齐的 View。

```Java
/** 获取需要对齐的View
 * @return 需要对齐的View
 */
public View findSnapView() {
    // 适配 TV
    if (null != getFocusedChild()) {
        return getFocusedChild();
    }
    if (getChildCount() <= 0) {
        return null;
    }
    // 以当前页面第一个View为基准
    int targetPos = getPageIndexByOffset() * mOnePageSize;   // 目标Pos
    for (int i = 0; i < getChildCount(); i++) {
        int childPos = getPosition(getChildAt(i));
        if (childPos == targetPos) {
            return getChildAt(i);
        }
    }
    // 如果没有找到就返回当前的第一个 View
    return getChildAt(0);
}

/** 根据 offset 获取页面 Index
 *  计算规则是，在当前状态下，哪个页面显示区域最大，就认为该页面是主要的页面，
 *。最终对齐时也会以该页面为基准。
 * @return 页面 Index
 */
private int getPageIndexByOffset() {
    int pageIndex;
    if (canScrollVertically()) {
        int pageHeight = getUsableHeight();
        if (mOffsetY <= 0 || pageHeight <= 0) {
            pageIndex = 0;
        } else {
            pageIndex = mOffsetY / pageHeight;
            if (mOffsetY % pageHeight > pageHeight / 2) {
                pageIndex++;
            }
        }
    } else {
        int pageWidth = getUsableWidth();
        if (mOffsetX <= 0 || pageWidth <= 0) {
            pageIndex = 0;
        } else {
            pageIndex = mOffsetX / pageWidth;
            if (mOffsetX % pageWidth > pageWidth / 2) {
                pageIndex++;
            }
        }
    }
    Logi("getPageIndexByOffset pageIndex = " + pageIndex);
    return pageIndex;
}
```

主要方法时 findSnapView，寻找当前应该对齐的 View，需要注意的是临界点的处理方案，例如在横向滚动的状态下，向左翻页未超过左侧页面中心位置，则松手后应该继续回到当前页面，若是超过了左侧页面中心位置，则松手后应该自动滚动到左侧页面。向右翻页同理，应该以当前状态下，显示区域最大的页面作为基准。

### 1.3 自定义 PagerGridSnapHelper

由于官方已经有了一个 PagerSnapHelper，为了避免混淆，我起名叫做 PagerGridSnapHelper。

由于官方已经实现了一些基础逻辑，所以实现一个 SnapHelper 还是比较简单的，主要是实现一些方法就行了，不过由于 SnapHelper 某些内容没有提供设置途径，因此我们会重载部分方法，所以下面的代码可能会看起来稍长，其实很简单。

```java
public class PagerGridSnapHelper extends SnapHelper {
    @Nullable
    @Override
    public int[] calculateDistanceToFinalSnap(@NonNull RecyclerView.LayoutManager layoutManager, @NonNull View targetView) {
        return new int[0];
    }

    @Nullable
    @Override
    public View findSnapView(RecyclerView.LayoutManager layoutManager) {
        return null;
    }

    @Override
    public int findTargetSnapPosition(RecyclerView.LayoutManager layoutManager, int velocityX, int velocityY) {
        return 0;
    }
}
```

继承 SnapHelper 后，它会让我们实现 3 个方法。

#### 1.3.1 计算到目标控件需要的距离

这里直接使用我们之前在 LayoutManager 中定义好的 getSnapOffset  就可以了。

```java
/**
 * 计算需要滚动的向量，用于页面自动回滚对齐
 *
 * @param layoutManager 布局管理器
 * @param targetView    目标控件
 * @return 需要滚动的距离
 */
@Nullable
@Override
public int[] calculateDistanceToFinalSnap(@NonNull RecyclerView.LayoutManager layoutManager,
                                          @NonNull View targetView) {
    int pos = layoutManager.getPosition(targetView);
    Loge("findTargetSnapPosition, pos = " + pos);
    int[] offset = new int[2];
    if (layoutManager instanceof PagerGridLayoutManager) {
        PagerGridLayoutManager manager = (PagerGridLayoutManager) layoutManager;
        offset = manager.getSnapOffset(pos);
    }
    return offset;
}
```

#### 1.3.2 获得需要对齐的 View

这个主要用于用户普通滚动停止时的对齐，直接使用之前 LayoutManager 中定义好的 findSnapView 就可以了。

```java
/**
 * 获得需要对齐的View，对于分页布局来说，就是页面第一个
 *
 * @param layoutManager 布局管理器
 * @return 目标控件
 */
@Nullable
@Override
public View findSnapView(RecyclerView.LayoutManager layoutManager) {
    if (layoutManager instanceof PagerGridLayoutManager) {
        PagerGridLayoutManager manager = (PagerGridLayoutManager) layoutManager;
        return manager.findSnapView();
    }
    return null;
}
```

#### 1.3.3 获取目标控件的位置下标

这个主要用于处理 Fling 事件，因此我们需要判断一下用户的 Fling 的方向，进而来获取需要对齐的条目，对于此处来说，就是上一页或者下一页的第一个条目。

```java
/**
 * 获取目标控件的位置下标
 * (获取滚动后第一个View的下标)
 *
 * @param layoutManager 布局管理器
 * @param velocityX     X 轴滚动速率
 * @param velocityY     Y 轴滚动速率
 * @return 目标控件的下标
 */
@Override
public int findTargetSnapPosition(RecyclerView.LayoutManager layoutManager,
                                  int velocityX, int velocityY) {
    int target = RecyclerView.NO_POSITION;
    Loge("findTargetSnapPosition, velocityX = " + velocityX + ", velocityY" + velocityY);
    if (null != layoutManager && layoutManager instanceof PagerGridLayoutManager) {
        PagerGridLayoutManager manager = (PagerGridLayoutManager) layoutManager;
        if (manager.canScrollHorizontally()) {
            if (velocityX > PagerConfig.getFlingThreshold()) {
                target = manager.findNextPageFirstPos();
            } else if (velocityX < -PagerConfig.getFlingThreshold()) {
                target = manager.findPrePageFirstPos();
            }
        } else if (manager.canScrollVertically()) {
            if (velocityY > PagerConfig.getFlingThreshold()) {
                target = manager.findNextPageFirstPos();
            } else if (velocityY < -PagerConfig.getFlingThreshold()) {
                target = manager.findPrePageFirstPos();
            }
        }
    }
    Loge("findTargetSnapPosition, target = " + target);
    return target;
}
```

为此我们需要在 LayoutManager 中再添加两个方法，就是做一些简单的计算，另外防止越界就可以了。

```Java
/**
 * 找到下一页第一个条目的位置
 *
 * @return 第一个搞条目的位置
 */
int findNextPageFirstPos() {
    int page = mLastPageIndex;
    page++;
    if (page >= getTotalPageCount()) {
        page = getTotalPageCount() - 1;
    }
    Loge("computeScrollVectorForPosition next = " + page);
    return page * mOnePageSize;
}

/**
 * 找到上一页的第一个条目的位置
 *
 * @return 第一个条目的位置
 */
int findPrePageFirstPos() {
    // 在获取时由于前一页的View预加载出来了，所以获取到的直接就是前一页
    int page = mLastPageIndex;
    page--;
    Loge("computeScrollVectorForPosition pre = " + page);
    if (page < 0) {
        page = 0;
    }
    Loge("computeScrollVectorForPosition pre = " + page);
    return page * mOnePageSize;
}
```

### 1.4 参数控制

实际上经过上面的步骤，一个简单的分页对齐辅助工具有完成了，但是有时手感可能会不太好，例如说 Fling 的触发速度，是需要用很大力气才能触发翻页操作呢，还是只需轻轻一划就会翻页呢，这个我们需要控制一下。

除此之外，还有就是自动滚动时的滚动速度控制，是很快的就滚动过去呢，还是慢慢的滚动到目标位置，官方提供的一些参数在实际应用时可能并不符合我们的需求，因此我们可以自定义一些参数来控制。

#### 1.4.1 控制 Fling 触发速度

官方使用的是 RecyclerView 的最小触发速度，但是这个速度我们无法设置，因此我们对这段代码重载一下，替换成我们自己定义的速度。

```java
/**
 * 一扔(快速滚动)
 *
 * @param velocityX X 轴滚动速率
 * @param velocityY Y 轴滚动速率
 * @return 是否消费该事件
 */
@Override
public boolean onFling(int velocityX, int velocityY) {
    RecyclerView.LayoutManager layoutManager = mRecyclerView.getLayoutManager();
    if (layoutManager == null) {
        return false;
    }
    RecyclerView.Adapter adapter = mRecyclerView.getAdapter();
    if (adapter == null) {
        return false;
    }
    // 官方方案
    // int minFlingVelocity = mRecyclerView.getMinFlingVelocity();
    
    // 替换成自定义触发速度
    int minFlingVelocity = PagerConfig.getFlingThreshold();
    Loge("minFlingVelocity = " + minFlingVelocity);
    return (Math.abs(velocityY) > minFlingVelocity || Math.abs(velocityX) > minFlingVelocity)
            && snapFromFling(layoutManager, velocityX, velocityY);
}
```

由于 snapFromFling 方法不是公开的，不可重载，我们按照官方实现复制过来一份就行了，此处没有贴出。

#### 1.4.2 控制滚动速度

自动滚动速度主要是有 SmoothScroller 来控制，此处我们自己进行创建 SmoothScroller 来控制平滑滚动的速度。

```java
/**
 * 通过自定义 LinearSmoothScroller 来控制速度
 * @param layoutManager 布局故哪里去
 * @return 自定义 LinearSmoothScroller
 */
protected LinearSmoothScroller createSnapScroller(RecyclerView.LayoutManager layoutManager) {
    if (!(layoutManager instanceof RecyclerView.SmoothScroller.ScrollVectorProvider)) {
        return null;
    }
    return new PagerGridSmoothScroller(mRecyclerView);
}
```

此处的 PagerGridSmoothScroller 是我们自己实现的，继承自 LinearSmoothScroller，很简单。

```java
public class PagerGridSmoothScroller extends LinearSmoothScroller {
    private RecyclerView mRecyclerView;

    public PagerGridSmoothScroller(@NonNull RecyclerView recyclerView) {
        super(recyclerView.getContext());
        mRecyclerView = recyclerView;
    }

    @Override
    protected void onTargetFound(View targetView, RecyclerView.State state, Action action) {
        RecyclerView.LayoutManager manager = mRecyclerView.getLayoutManager();
        if (null == manager) return;
        if (manager instanceof PagerGridLayoutManager) {
            PagerGridLayoutManager layoutManager = (PagerGridLayoutManager) manager;
            int pos = mRecyclerView.getChildAdapterPosition(targetView);
            int[] snapDistances = layoutManager.getSnapOffset(pos);
            final int dx = snapDistances[0];
            final int dy = snapDistances[1];
            Logi("dx = " + dx);
            Logi("dy = " + dy);
            final int time = calculateTimeForScrolling(Math.max(Math.abs(dx), Math.abs(dy)));
            if (time > 0) {
                action.update(dx, dy, time, mDecelerateInterpolator);
            }
        }
    }

    @Override
    protected float calculateSpeedPerPixel(DisplayMetrics displayMetrics) {
        return PagerConfig.getMillisecondsPreInch() / displayMetrics.densityDpi;
    }
}
```

经过这些步骤之后，一个可调控，简单方便的分页对齐工具就开发完成了，可以像这样使用了。

```java
// 设置滚动辅助工具
PagerGridSnapHelper pageSnapHelper = new PagerGridSnapHelper();
pageSnapHelper.attachToRecyclerView(mRecyclerView);
```



## 2. 处理滚动到指定条目(页面)

在上面一篇文章中，只是简单的开发了一个分页网格布局，该网格布局实现了布局和基本的滚动处理，经过本篇的上半篇文章，实现了分页对齐功能。

但是，该分页布局管理器依旧存在问题，例如，你会发现它只能手动的进行滚动，你无法用代码控制它滚动到距离的条目和页面，例如，你调用 `recyclerView.scrollToPosition(0);` 它是没有任何响应的。这是因为我们没有处理滚动到指定条目的方案。

### 2.1 直接滚动

由于我们是页面对齐，所以滚动到指定条目，也就是滚动到指定条目所在到页面，因此我们可以这样写。

```java
public void scrollToPosition(int position) {
    int pageIndex = getPageIndexByPos(position);
    scrollToPage(pageIndex);
}
```

先计算出条目所在页面的下标，然后滚动到该页面。但是 scrollToPage 方法需要我们自己实现一下，逻辑也很简单，如下：

```java
public void scrollToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= mLastPageCount) {
        Log.e(TAG, "pageIndex = " + pageIndex + " is out of bounds, mast in [0, " + mLastPageCount + ")");
        return;
    }

    if (null == mRecyclerView) {
        Log.e(TAG, "RecyclerView Not Found!");
        return;
    }

    int mTargetOffsetXBy = 0;
    int mTargetOffsetYBy = 0;
    if (canScrollVertically()) {
        mTargetOffsetXBy = 0;
        mTargetOffsetYBy = pageIndex * getUsableHeight() - mOffsetY;
    } else {
        mTargetOffsetXBy = pageIndex * getUsableWidth() - mOffsetX;
        mTargetOffsetYBy = 0;
    }
    Loge("mTargetOffsetXBy = " + mTargetOffsetXBy);
    Loge("mTargetOffsetYBy = " + mTargetOffsetYBy);
    mRecyclerView.scrollBy(mTargetOffsetXBy, mTargetOffsetYBy);
    setPageIndex(pageIndex, false);
}
```

其实就是先计算出目标页面的坐标，然后计算滚动到该位置需要的距离，最后调用 RecyclerView 的滚动就可以了。

但是，在 LayoutManager 中是无法直接取到 RecyclerView 的，因此我们在 onAttachedToWindow 方法中获得当前 LayoutManager 的 RecyclerView，并记录下来。

```java
private RecyclerView mRecyclerView;

@Override
public void onAttachedToWindow(RecyclerView view) {
    super.onAttachedToWindow(view);
    mRecyclerView = view;
}
```

在有了 scrollToPage 方法后，我们还可以定义两个常用的方法，上一页和下一页，来供外部使用。

```java
/**
 * 上一页
 */
public void prePage() {
    scrollToPage(getPageIndexByOffset() - 1);
}

/**
 * 下一页
 */
public void nextPage() {
    scrollToPage(getPageIndexByOffset() + 1);
}
```

就这样，直接滚动就处理好了。

### 2.2 平滑滚动

和直接滚动一样，我们同样实现平滑滚动到指定条目，平滑滚动到指定页面，上一页，下一页等功能，实现方式页和直接滚动类似，将所有的操作都统一转化为滚动到指定页面，最终有滚动到指定页面来实现具体功能。

```java
// 平滑滚动到指定条目
@Override
public void smoothScrollToPosition(RecyclerView recyclerView, RecyclerView.State state, int position) {
    int targetPageIndex = getPageIndexByPos(position);
    smoothScrollToPage(targetPageIndex);
}

// 平滑滚动到上一页
public void smoothPrePage() {
    smoothScrollToPage(getPageIndexByOffset() - 1);
}

// 平滑滚动到下一页
public void smoothNextPage() {
    smoothScrollToPage(getPageIndexByOffset() + 1);
}

// 平滑滚动到指定页面
public void smoothScrollToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= mLastPageCount) {
        Log.e(TAG, "pageIndex is outOfIndex, must in [0, " + mLastPageCount + ").");
        return;
    }
    if (null == mRecyclerView) {
        Log.e(TAG, "RecyclerView Not Found!");
        return;
    }

    // 如果滚动到页面之间距离过大，先直接滚动到目标页面到临近页面，在使用 smoothScroll 最终滚动到目标
    // 否则在滚动距离很大时，会导致滚动耗费的时间非常长
    int currentPageIndex = getPageIndexByOffset();
    if (Math.abs(pageIndex - currentPageIndex) > 3) {
        if (pageIndex > currentPageIndex) {
            scrollToPage(pageIndex - 3);
        } else if (pageIndex < currentPageIndex) {
            scrollToPage(pageIndex + 3);
        }
    }

    // 具体执行滚动
    LinearSmoothScroller smoothScroller = new PagerGridSmoothScroller(mRecyclerView);
    int position = pageIndex * mOnePageSize;
    smoothScroller.setTargetPosition(position);
    startSmoothScroll(smoothScroller);
}
```

和直接滚动不同的是，平滑滚动会有一个简单的滚动动画效果，这个动画效果借助 SmoothScroller 来实现，为了保证滑动效果一致，我们使用和 SnapHelper 相同的 PagerGridSmoothScroller。

**需要注意的是，在进行超长距离的平滑滚动时，如果不做特殊处理，可能要滚动很长的时间(会花费超过 10s 甚至更长的时间在滚动上)，为了限制平滑滚动花费的时间，这里对滚动距离做了一个简单的限制，即最大可以平滑滚动 3 个页面的长度，如果超过 3 个页面的长度后，则先直接跳转到临近页面，再执行平滑滚动，这样就可以保证很快执行完超长距离的平滑滚动，具体代码逻辑参考上面。**



## 3. 结语

到此为止，一个简单的网格分页布局管理器(PagerGridLayoutManager)和分页辅助工具(PagerGridSnapHelper)就开发完了，当然，这个库还有很多可以完善的地方，事实上，在写本文的同时，我又对它很多的细节又重新打磨了一遍。因此你如果查看就版本的话，代码内容可能会稍有不同，但基本逻辑是相同的。

如果喜欢本文的话，欢迎点赞、分享或者打赏支持。

#### **关于作者**

GcsSloop，一名 2.5 次元魔法师。

