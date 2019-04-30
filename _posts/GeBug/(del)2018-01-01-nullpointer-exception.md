---
layout: post
category: GeBug
title: 雕虫晓技(四) 诡异的空指针
tags: Android
keywords: Android
excerpt: 多线程中诡异的空指针，用 final 局部变量指向全局变量可以解决该问题。
---

### 关于作者

GcsSloop，一名 2.5 次元魔法师。  
[微博](http://weibo.com/GcsSloop/home) | [GitHub](https://github.com/GcsSloop) | [博客](http://www.gcssloop.com/)

![](http://gcsblog.oss-cn-shanghai.aliyuncs.com/blog/2019-04-29-073241.jpg?gcssloop)

## 前言

这件事情呢，要从一段简单的代码说起，还记得那是一个风和日丽的下午，我熟练的打开了陪伴我多年的IDE，看着那熟悉的界面，我开开心心的写下了如下的代码：

```java
private static String mStr = null;

private static void printStrLength() {
    if (null != mStr) {
        int len = mStr.length();
        System.out.println("length = " + len);
    }
}
```

我有一个全局的变量 mStr，我想要输出它的长度，于是我写了这样一个方法，这种问题对于我这样的老司机来说，自然是很 Easy 的，相信大家从  `if (null != mStr)` 就已经看出了我是一个经验丰富的专家，时刻提防着空指针来破坏我的代码运行。

当我自信的按下运行按钮时，不可思议的事情发生了，我的代码居然出现了异常，居然是空指针，并且发生在几乎是不可能出现的位置。

![](http://gcsblog.oss-cn-shanghai.aliyuncs.com/blog/2019-04-29-073242.jpg?gcssloop)

这不是我的错，一定是运行时出现了问题，沉思片刻后，我决定再试一次！

当相同的错误在此出现的时候，我发觉了，这一定是 IDE 出现了 bug，于是我决定重启一下我的 IntelliJ IEAD。

当 IDE 重启完毕，我再次运行，发现错误依旧出现，此时我觉得可能是我的电脑太古老了，也许应该换一台试试，当然，也有可能是我的 java 虚拟机坏掉了 ...

## 诡异的空指针

说到空指针，这应该是 java 语言中最常见，也是最让人头疼的异常之一了，上面和大家开个玩笑，其实这个空指针异常是我精心制造出来的，就是因为他比较有趣，不仅触发方式有趣，解决方式也很有趣。

下面给大家看一下制造这个空指针异常的完整代码：

```java
public class GcsTest {

    private static String mStr = null;

    private static void printStrLength() {
        if (null != mStr) {
            int len = mStr.length();
            System.out.println("length = " + len);
        }
    }

    public static void main(String[] args) {
        GThreadA threadA = new GThreadA();
        GThreadB threadB = new GThreadB();
        threadA.start();
        threadB.start();
    }

    static class GThreadA extends Thread {
        @Override
        public void run() {
            while (true) {
                if (null == mStr) {
                    mStr = "Gcs";
                } else {
                    mStr = null;
                }
            }
        }
    }

    static class GThreadB extends Thread {
        @Override
        public void run() {
            while (true) {
                printStrLength();
            }
        }
    }
}
```

代码并不复杂，本质上就是两个线程，第一个线程(GThreadA)负责不断修改 `mStr` 的状态，第二个线程(GThreadB)则不断调用 `printStrLength()` 方法，尝试输出 mStr 的长度。

如果正常运行的话，输出结果应该是下面这样的：

```shell
length = 3
length = 3
length = 3
length = 3
length = 3
length = 3
length = 3
...
```

但是，你运行的时候就会发现，它几乎是一定会出现空指针异常的，有时可能会正常运行一段时间后再出现，有时刚开始运行就出现了。

这个问题表面是空指针引起的，但核心是线程并发问题。观察下面这段代码，是没有任何问题的，在单线程上运行时，它是安全的代码，但遇到多线程并发就不一定了。

```java
private static void printStrLength() {
    if (null != mStr) {
        int len = mStr.length();
        System.out.println("length = " + len);
    }
}
```

由于线程可能在任意位置中断并切换到其它线程，所以就可能出现如下这种情况：

**当 threadB 刚判断完 if(null != mStr) 这句话之后，切换到了 threadA，此时 threadA 也判断 mStr 不为 null，于是将 mStr 置为了 null，之后再切换到 threadB，当 threadB 获取长度的时候就发生了空指针异常。在并发的情况下执行顺序可能是这样的：**

```java
//前置条件： mStr 不为 null
//threadB
if(null != mStr){
//切换线程到 threadA
  if(null == mStr){
    ...
  } else{
    mStr = null;
  }
//切换线程到 threadB
  int len = mStr.length(); // <-- 发生异常
}
```

现在我们已经知道问题的根源了，就是线程可能在代码执行的任意位置切换，如果在切换之后一些全局状态改变了，那么切换回来之后之前的判断条件其实是无效的。

既然发现了问题的根源，那就容易解决了，多线程并发问题，要不加个锁试试？但是仔细想想这个锁应该怎么加呢？

首先两个线程访问的是不同的代码块，不存在访问冲突，那么方法锁和类锁基本可以判断是无效的。

两个线程唯一共用的对象就是 mStr，所以看起来比较靠谱的方案就是把 mStr 这个对象锁起来，但是 mStr 又可能为 null，如果 mStr 为 null，那么加对象锁的时候就会直接抛出空指针异常！所以加锁之前最好用先判断 mStr 不为 null 再加锁。

额，再想想，这个和上面的操作有啥区别，由于多线程可能在任意位置切换，所以不论在哪里加 if 条件基本都形同虚设，这个简单的问题难道就无解了？

![](http://gcsblog.oss-cn-shanghai.aliyuncs.com/blog/2019-04-29-073243.jpg?gcssloop)

## 解决方案

其实在这里加锁并不能解决问题，也不是一种好方案，众所周知，加锁的本质上是资源访问互斥，即当一个线程操作时进行锁定，在锁定期间其它任何线程都不允许访问，所以加锁会影响程序运行的性能，因此在非必要的情况下，能不用锁就尽量不用。

而且在上面这段代码中，mStr 是不断进行变化的，它的变化不应该受到外界操作的影响。举一个不太恰当的例子：
天气是不断变化的，我在天气好的时候出门逛街，天气不好的时候呆在家里打游戏，我根据天气状况来决定自己的活动，但是我是不能影响天气的，不能说，现在天气很好，我出门去逛街，为了防止突然下雨把我淋湿，我就把天气状态锁定到当前的好天气状态，当我逛完街回来，再释放天气状态，让天气继续变化。这显然即不符合逻辑也行不通。

在 Android 中一个比较类似的事情就是事件机制，只要用户在触摸，就不断会有事件产生，不论你是否使用，这些事件都在不断的产生，作为一个程序，并不能因为自己需要当前这一时刻的事件，就把事件锁定，不让其产生新的触摸事件。

**实质上，我们需要的仅仅是当下这一时刻的状态，并根据当下这一时刻的状态来决定我们接下来要做什么。**

分析完问题的本质，问题就已经解决了，我们需要的是当下这一刻的状态，那么把这一刻的状态保存下来不就行了？只用简单的修改一下代码，就能实现这一需求了：

**先使用一个 final 的局部变量指向全局变量，之后再对这个变量进行操作。**

```java
private static void printStrLength() {
    // 使用 final 关键字保存当前状态
    final String str = mStr;
    if (null != str) {
        int len = str.length();
        System.out.println("length = " + len);
    }
}
```

**我们这里使用 final 关键字将当前状态快照下来并用一个局部变量保存，之后的所有操作都只访问这个局部变量，由于这个局部变量是不会变化的，所以，即便发生上面的那种情况，判断完 if 条件后，线程切换出去改变了全局变量的状态，也不会影响到后续的操作。这也算是 final 关键字取巧的一种用法吧。**

## 结语

其实你阅读 Android 源码的话，是经常可以见到使用一个 final 局部变量指向全局变量这种写法的，起初看到这种写法甚是不解，感觉这不是多此一举吗？直到我遇见了上面这种诡异的异常，才明白这种写法的精妙之处。

本文虽然啰嗦了那么多内容，其实本质上总结起来就一句话：**使用 final 关键字快照当前全局变量的状态，可以防止特定情况下的多线程并发问题。**

虽然这是一种好方法，但也只是适用于特定的情况，并非万金油，当遇到问题时还是需要根据具体情况进行分析，从而得到合适的解决方案。

**关于作者**

GcsSloop，一名 2.5 次元魔法师。