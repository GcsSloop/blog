---
layout: post
category: GeBug
title: 雕虫晓技(九) Netty与私有协议框架
tags: Android
keywords: Android, rxjava, netty, protocol
excerpt: Netty与私有协议
typora-root-url: ../../../Source
---

### 关于作者

GcsSloop，一名 2.5 次元魔法师。  
[微博](http://weibo.com/GcsSloop/home) | [GitHub](https://github.com/GcsSloop) | [博客](http://www.gcssloop.com/)

![](http://gcsblog.oss-cn-shanghai.aliyuncs.com/blog/2019-04-29-073240.jpg?gcssloop)

## 1.前言

**[【本文示例源码下载】](http://android.demo.gcssloop.com/C0DE_Sample.zip)**

在本系列的前一篇，说了 Android 与数据流的斗争，主要是 Android 前端自身处理方案。这一篇则是涉及一些前后端方面的数据传输的问题。

通常来说，Android 和服务端之间的数据传输都会采用标准协议规范，且大多数是基于 HTTP 协议的，例如在Android端最常用的 Retrofit，则是 RESTful 风格的一套网络框架。虽然这是我们最常用的框架之一，但是很多人对该框架了解并不是特别深入，只知道用它可以和服务器进行交互，但是对于它在网络交互中到底处于哪一位置则比较模糊，下面就带大家看一下：

```
+=================================+
|    协议    | ---> |   对应的工具  |
+=================================+
      |                    |
      ∇                    ∇
+-----------+      +--------------+
|  RESTful  | ---> |   Retrofit   |
+-----------+      +--------------+
      |                    |
      ∇                    ∇
+-----------+      +--------------+
|   HTTP    | ---> |    OkHttp    | 
+-----------+      +--------------+
     |                     |
     ∇                     ∇
+-----------+       +-------------+
|  TCP/IP   | --->  | Socket+Okio |
+-----------+       +-------------+
     |                     |
     ∇                     ∇
+-----------+       +-------------+
| 更底层协议  | --->  |  更底层工具  |
+-----------+       +-------------+
```

在上面，左侧是对应的一些协议规范，右侧则是对这些协议规范实现的相关工具，当然任何一套规范都有多种实现工具可以用，上面只是在 Android 平台最常用的一套实现方案而已。

**相信学过计算机网络相关的同学都知道“OSI网络七层模型”和“TCP/IP五层模型”，我们的网络正是建立在这些模型之上的，而这些模型实际上是一套又一套的规范。** 这些规范与语言无关，与平台设备无关，不论你用什么设备，使用什么语言进行开发，只要遵守这一套规范就可以接入现有的网络。正因如此，我们现在的各种设备才可以通过网络进行相互的通信，交流。

## 2.标准协议与私有协议

上面是一些标准协议，即一种公开的，大家都采用的一种协议，在目前的工作中，我们大部分情况也会采用标准协议，因为标准协议都会有成熟的库可以用，可以快速的进行业务开发，而不用纠结各种底层通信的各种问题。

### 2.1 私有协议适用场景

凡事都有例外，标准协议固然好，但在某些特定的场景下却不一定合适。

**性能限制：**我们需要和一些智能设备(物联网设备)直接进行通信，受限于这些设备的性能功耗等问题，无法承载部分标准协议库过大的内存消耗。  
**实时性要求：**又或者我们本身需要传输的数据就很简单，而且需要较高的实时性，而部分标准协议每一次传输都需要携带很多的冗余内容，这明显会降低数据解析速度。  
**安全性：**还有另外一个原因则是为了安全，私有协议固然也可能会被逆向破解，但由于私有协议的保密性，破解起来会更加麻烦，也更耗费时间，如果发现被破解了，更新一下协议规范就可以直接让之前的破解失效。  

### 2.2 私有协议缺陷

当然，私有协议也并非全是好处，不然目前也不可能是标准协议的天下了。首先还是安全性，其次开发速度，当然第三方对接也是大问题。  
**安全性：**私有协议虽然因为规范保密而让其显得“更安全”，但规范一旦被泄露，安全性也就无从谈起了。部分协议设计者觉得协议是私有的，就在安全设计方面稍为欠缺了一点考虑，导致协议规范一旦被泄露，内容也就跟着被泄露了。相比之下，标准协议固然都是使用同一套标准，但是其安全性却更高一筹，对于需要保密的内容，在你知道协议规范的前提下依旧是难以破解的。  
**开发速度：** 私有协议就意味着没有标准库可以使用，需要完全自己进行开发和解析。这样无疑会降低前期的开发速度。而开发速度对于企业来说则意味着大量的人力成本，对于部分企业而言，是不愿意承担这样的成本的。  
**第三方对接：** 现在很少有企业会单独运作，多多少少都会和其他的企业有所业务往来，因此双方的部分系统就需要考虑对接问题，如果双方企业均采用私有协议，无疑还是会加大对接的成本，对企业来说可能并不是一件好事。

## 3. 私有协议开发

作为一名 Android 程序员，虽然用到私有协议的机会可能比较少，但是也有碰到需要用的时候，既然用到了那也不能虚，毕竟技术学习永无止境。我最近在公司也就遇上的需要用到私有协议的地方，因此也对私有协议了解了一下，学习了一下如何封装私有协议。

封装协议不比调用网络库，自己封装协议需要考虑的东西又很多，例如：数据包格式，数据包的拆包和封包，如何保持长连接，掉线如何自动重连，多个线程之间通信的处理方案，如何与前端隔离，即调用过程透明化。这么说吧，封装一个协议很简单，但是如果想要封装好则比较困难的。下面带大家实现一个自定义协议，并将其封装起来。

这里主要使用到了 Netty 框架和 RxJava 相关技术，有关 Netty 相关的技术个人推荐看 《Netty 实战》这本书，当然自己去搜索网络博客也是可以的，对于 Netty 的基本使用方法，不在本文范围之内。

### 3.1 私有协议规范(C0DE协议)

**由于是简单教程向，协议自然也不能设计的太复杂，下面带大家实现一个我自定义的 `C0DE` 协议。 是 C0DE，不是 CODE，里面是数字 0。**

#### 3.1.1 基本包结构

<table class="tableizer-table" align="center">
<thead >
    <tr class="tableizer-firstrow">
        <th colspan="4">帧头</th><th>内容</th><th colspan="2">帧尾</th>
    </tr>
</thead>
<tbody>
 <tr><td>1 byte</td><td>1 byte</td><td>4 byte</td><td>4 byte</td><td>-</td><td>2 byte</td><td>1 byte</td></tr>
 <tr><td>0xC0</td><td>帧类型</td><td>确认码</td><td>内容长度</td><td>内容，可能没有</td><td>CRC 校验码</td><td>0xDE</td></tr>
</tbody>
</table>

- 0xC0：表示一帧的开始
- 帧类型：表示该帧的功能(不可以与帧头、帧尾重复)
- 确认码：该帧的唯一标记，用于区分不同的帧，每一帧的确认码都应该不同，服务端给客户的响应，确认码应与客户端发送的确认码相同。
- 内容长度：内容区域的长度，可能为0
- 内容：存放的内容，长度不定。
- CRC校验：使用  CRC-16/XMODEM 标准进行校验，校验范围：帧类型、确认码、内容长度和内容。用于验证内容的完整性。
- 0xDE：表示一帧的结束。

**转义：**

为了防止内容区域出现于帧头、帧尾相同的内容，导致无法准确的获取一帧的内容，所以设立了的转义规则，在帧头和帧尾之间遇到特殊字段都需要进行转义。防止出现冲突。

- 0xC0  -> 0xAD 0x00
- 0xDE -> 0xAD 0x01
- 0xAD -> 0xAD 0x02

> **注意：** 该帧结构没有设计加密，是明文格式，在实际运用中需要对内容区域进行加密，加密方案则需要前后端采用统一的标准。

#### 3.1.2 心跳命令

由于网络环境比较复杂，如果客户端和服务端长时间没有联系的话，就会可能被中间的传输设备默认进行断开，如果需要保持长连接的话，就需要发送一些空数据包作为心跳数据，以避免被中间设备断开。

**客户端发送帧：**

<table class="tableizer-table" align="center">
<thead >
    <tr class="tableizer-firstrow">
        <th colspan="4">帧头</th><th>内容</th><th colspan="2">帧尾</th>
    </tr>
</thead>
<tbody>
 <tr><td>1 byte</td><td>1 byte</td><td>4 byte</td><td>4 byte</td><td>-</td><td>2 byte</td><td>1 byte</td></tr>
 <tr><td>0xC0</td><td>0x00</td><td>确认码</td><td>0</td><td>无</td><td>CRC 校验码</td><td>0xDE</td></tr>
</tbody>
</table>

**服务端响应帧：**

<table class="tableizer-table" align="center">
<thead >
    <tr class="tableizer-firstrow">
        <th colspan="4">帧头</th><th>内容</th><th colspan="2">帧尾</th>
    </tr>
</thead>
<tbody>
 <tr><td>1 byte</td><td>1 byte</td><td>4 byte</td><td>4 byte</td><td>-</td><td>2 byte</td><td>1 byte</td></tr>
 <tr><td>0xC0</td><td>0x00</td><td>确认码</td><td>0</td><td>无</td><td>CRC 校验码</td><td>0xDE</td></tr>
</tbody>
</table>

#### 3.1.3 2233命令

2233 由客户端发送一个 22 命令，服务端收到后回复一个 33，该命令没有内容。

**客户端发送帧：**

<table class="tableizer-table" align="center">
<thead >
    <tr class="tableizer-firstrow">
        <th colspan="4">帧头</th><th>内容</th><th colspan="2">帧尾</th>
    </tr>
</thead>
<tbody>
 <tr><td>1 byte</td><td>1 byte</td><td>4 byte</td><td>4 byte</td><td>-</td><td>2 byte</td><td>1 byte</td></tr>
 <tr><td>0xC0</td><td>0x22</td><td>确认码</td><td>0</td><td>无</td><td>CRC 校验码</td><td>0xDE</td></tr>
</tbody>
</table>

**服务端响应帧：**

<table class="tableizer-table" align="center">
<thead >
    <tr class="tableizer-firstrow">
        <th colspan="4">帧头</th><th>内容</th><th colspan="2">帧尾</th>
    </tr>
</thead>
<tbody>
 <tr><td>1 byte</td><td>1 byte</td><td>4 byte</td><td>4 byte</td><td>-</td><td>2 byte</td><td>1 byte</td></tr>
 <tr><td>0xC0</td><td>0x33</td><td>确认码</td><td>0</td><td>无</td><td>CRC 校验码</td><td>0xDE</td></tr>
</tbody>
</table>

#### 3.1.2 内容命令

客户端发送一段内容，服务端收到后返回另一段内容，例如：当客户端发送内容为 `Fu` 时，服务端收到会返回一个 `ck`.

**客户端发送帧：**

<table class="tableizer-table" align="center">
<thead >
    <tr class="tableizer-firstrow">
        <th colspan="4">帧头</th><th>内容</th><th colspan="2">帧尾</th>
    </tr>
</thead>
<tbody>
 <tr><td>1 byte</td><td>1 byte</td><td>4 byte</td><td>4 byte</td><td>-</td><td>2 byte</td><td>1 byte</td></tr>
 <tr><td>0xC0</td><td>0x01</td><td>确认码</td><td>内容长度</td><td>内容</td><td>CRC 校验码</td><td>0xDE</td></tr>
</tbody>
</table>

**服务端响应帧：**

<table class="tableizer-table" align="center">
<thead >
    <tr class="tableizer-firstrow">
        <th colspan="4">帧头</th><th>内容</th><th colspan="2">帧尾</th>
    </tr>
</thead>
<tbody>
 <tr><td>1 byte</td><td>1 byte</td><td>4 byte</td><td>4 byte</td><td>-</td><td>2 byte</td><td>1 byte</td></tr>
 <tr><td>0x01</td><td>0x01</td><td>确认码</td><td>内容长度</td><td>内容</td><td>CRC 校验码</td><td>0xDE</td></tr>
</tbody>
</table>

最终定义了 3 条指令，下面就看如何将这些指令封装起来。

### 3.2 协议封装

**这里我们使用 Netty(4.0.56版本) 来做服务端与客户端，其中客户端与以调用者之间则使用 RxJava(2.1.16版本)，使用 intelliJ IEDA 作为开发工具。**由于是使用 Java 语言进行开发的，你可以将其直接移植到 Android 项目中，而不用更改代码内容。

你可以在文初或者文末下载到相关的 IntelliJ 工程代码，本文限于篇幅并不会将所有的代码内容都讲解到，如果有疑惑，可以去直接查看源代码。

> 有人可能会疑惑，Netty 主要是用 java 开发的，那么服务端和 Android 都是用 java 就可以了，但是如果需要在 iOS 端使用怎么办？协议本身就是与平台和语言无关的，iOS 上也有网络交互逻辑，只需要按照协议规范发送数据就可以了，不是必须使用 Netty 框架。当然，由于我本身对 iOS 开发了解有限，因此本文也就没有 iOS 相关的内容了。

既然是要将私有协议封装起来，那么就要有一定的结构，最终设计出来的结构如下：

**服务端：**

![Server_arch](/assets/gebug/09-netty-private-protocol/Server_arch.jpg)

服务端设计的结构比较简单，网络数据流在经过解码器之后转化为 Packet，各个 Packet 通过 Netty 分发到对应的  Handler 进行处理，Handler 处理结束后，将需要发送到内容封装成 Packet 发送，Packet 通过 Encoder 转换为 byte[]， 然后通过网络送到客户端。

**客户端：**

![Client_arch](/assets/gebug/09-netty-private-protocol/Client_arch.jpg)

> 绿色的线条表示发送的数据经过的主要路径。
>
> 橙色线条表述服务器返回结果数据经过的主要路径。

可以看出，客户端的设计相对来说要复杂更多，这是因为客户端需要考虑到对图形化界面对支持和调用的透明化(即上层调用者完全无需知道底层的实现方案和逻辑)。除此之外，由于网络的不确定性，接受到的返回结果顺序未必和发送顺序一致，因此就需要对接收到的结果进行甄别，判断是那一次请求的返回结果(Frame里面的确认码就是用于区分返回结果属于哪一请求的)。因此，客户端的逻辑设计就变得更加复杂，不过得益于 Netty 良好的设计，这种复杂程度还是可以接受的。

上层调用者只需关心 API 层都提供了哪些方法可以使用，而 API 调用层只和 Service 有限的接口进行交互，最终和服务器交互的一切细节都被隐藏在 Service 中。

Service 不仅负责两个输入输出队列的基本管理，还需要负责保持与服务端的长连接，以及断线重连机制。尽管需要处理的内容稍微有点多，但是在 Netty 框架强力的支持下，只用了不到 400 行代码就实现了所有的功能。

管理总览先看这么多，下面看一下里面的部分实现细节。

#### 3.2.1 工具类

项目中主要是工具类有两个，一个是 CRC 校验工具，另一个则是 byte 数组和其他数据相互转换的工具。

**CRCUtils：** CRC 校验存在多个不同的标准，因此服务端与客户端使用标准必须统一，我这里采用了 CRC-16/XMODEM  标准。关于 CRC 校验工具的代码网上随处可见，我这里也只是根据网络代码简单封装了一下，具体可以看项目中。

**ByteUtils： ** 由于通过网络传输的数据都是 byte 数组，所有的数据都绕不开数据转换过程，这里也只是简单的封装了一些常用的转换方法，这些方法都是随处可以查到的，详情依旧见项目中。

#### 3.2.2 基础数据包

由于我们最终发送的任何数据都是 `byte[]` 我可以直接把需要发送的数据直接按照规范写到 `byte[]` 然后发送出去，但是呢，这样直接写数据显然是很不直观的，例如：`C0 00 00 00 00 01 00 00 00 00 AA 51 DE` 就是一个简单的心跳数据包，但是谁能一眼看出来这是个心跳包呢？这样显然是不合适的。因此需要将其封装为数据包，如用 `GHeartPacket` 表示心跳数据包，需要心跳数据的时候直接创建一个 `GHeartPacket` 发送，这样会直观很多，而且不容易出错。

在封装之前，先观察一下协议的基本结构：

<table class="tableizer-table" align="center">
<thead >
    <tr class="tableizer-firstrow">
        <th colspan="4">帧头</th><th>内容</th><th colspan="2">帧尾</th>
    </tr>
</thead>
<tbody>
 <tr><td>1 byte</td><td>1 byte</td><td>4 byte</td><td>4 byte</td><td>-</td><td>2 byte</td><td>1 byte</td></tr>
 <tr><td>0xC0</td><td>帧类型</td><td>确认码</td><td>内容长度</td><td>内容，可能没有</td><td>CRC 校验码</td><td>0xDE</td></tr>
</tbody>
</table>

首先，帧头和帧尾是固定不变的，内容长度 和 CRC校验码是计算出来的，实际上我们各种数据包主要变化的内容就是 帧类型，确认码和内容而已，因此我们可以将不变的或者可以计算得出的内容抽象出来，作为基础的数据包，而最终的数据包，继承自该基础数据包，并提供变动的内容即可。

**基础的数据包提供一个 getFrameBytes() 的抽象方法，该方法最终生成的数据就是通过网络发送的数据，同时提供数据打包，数据转义和反转义功能**，最终看起来是这样子：

```java
/**
 * 基础发送数据包
 * 基本的帧结构
 * +----------+----------+--------------------------------------------------------
 * |  大小    |  固定值   |  摘要
 * +----------+----------+--------------------------------------------------------
 * | 1 bytes  | 0xC0     |  帧起始符
 * | 1 bytes  |          |  帧类型
 * | 4 bytes  |          |  确认码
 * | 4 bytes  |          |  内容长度
 * |          |          |  内容
 * | 2 bytes  |          |  校验码 CRC 校验
 * | 1 bytes  | 0xDE     |  帧结束符
 * +----------+----------+--------------------------------------------------------
 * 加密范围:帧类型+确认码+内容长度+内容.
 */
public abstract class Packet {
    //--- 通用数据 ---
    public static final byte HEAD = (byte) 0xC0;    // 帧头
    public static final byte TAIL = (byte) 0xDE;    // 帧尾

    private static final byte REVISE_CODE = (byte) 0xAD;    // 转义码
    private static final byte REVISE_HEAD = (byte) 0x00;    // 头部
    private static final byte REVISE_TAIL = (byte) 0x01;    // 尾部
    private static final byte REVISE_SELF = (byte) 0x02;    // 自身
    //--- 通用数据结束 ---

    private int mCode;  // 响应吗，一帧的唯一标识符号

    public Packet() {
    }

    /**
     * 创建一帧同时设置响应码
     *
     * @param code 响应码
     */
    public Packet(int code) {
        mCode = code;
    }

    /**
     * 获取帧数据(byte[]), 该数据可以直接通过 TCP 协议进行发送.
     *
     * @return 帧数据
     */
    public abstract byte[] getFrameBytes();

    /**
     * 原始数据转换到帧数据,CRC校验,头部和尾部以及相关信息.
     *
     * @param type 帧类型
     * @param code 确认码
     * @param data 原始数据
     * @return 帧数据
     */
    public static byte[] packet(byte type, int code, @Nullable byte[] data) {
        int data_len = 0;
        if (null != data) {
            data_len = data.length;
        }
        int total_len = data_len + 11;                  // 总长度
        ByteBuffer buffer = ByteBuffer.allocate(total_len);   // 分配一个合适大小的区域
        buffer.put(type);                               // 添加帧类型
        buffer.putInt(code);                            // 添加响应码
        buffer.putInt(data_len);                        // 数据长度
        if (null != data) {
            buffer.put(data);                           // 添加数据
        }

        // 获取 CRC 数据
        buffer.flip();                                  // 准备读取数据
        buffer.mark();                                  // mark 指针位置, 防止读取后该部分数据被清除
        byte[] crc_data = new byte[buffer.limit()];     // 分配空间(之前所有的数据都参与 CRC 校验)
        buffer.get(crc_data);                           // 获取数据
        buffer.reset();                                 // 重置指针位置
        buffer.compact();                               // 切换到写状态
        short crc = CRCUtils.getCRC(crc_data);          // 计算 CRC
        buffer.putShort(crc);                           // 添加 CRC

        // 数据转义
        byte[] content = revise((byte[]) buffer.flip().array());

        // 添加头尾
        ByteBuffer frame = ByteBuffer.allocate(content.length + 2);
        frame.put(HEAD);
        frame.put(content);
        frame.put(TAIL);

        return (byte[]) frame.flip().array();          // 返回最终结果
    }

    /**
     * 转义
     *
     * @param raw 原始数据
     * @return 转义后数据
     * 0xC0 -> 0xAD 0x00
     * 0xDE -> 0xAD 0x01
     * 0xAD -> 0xAD 0x02
     */
    public static byte[] revise(byte[] raw) {
        ByteBuffer temp = ByteBuffer.allocate(raw.length * 2);
        for (byte b : raw) {
            if (b == HEAD) {
                temp.put(REVISE_CODE).put(REVISE_HEAD);
            } else if (b == TAIL) {
                temp.put(REVISE_CODE).put(REVISE_TAIL);
            } else if (b == REVISE_CODE) {
                temp.put(REVISE_CODE).put(REVISE_SELF);
            } else {
                temp.put(b);
            }
        }

        int ret_len = temp.position();
        byte[] ret = new byte[ret_len];
        temp.flip();
        temp.get(ret);
        return ret;
    }

    /**
     * 还原,反转义
     *
     * @param raw 转义后的数据
     * @return 原始数据
     * 0xAD 0x00 -> 0xC0
     * 0xAD 0x01 -> 0xDE
     * 0xAD 0x02 -> 0xAD
     * @throws Exception 发现不符合转义要求的数据，抛出异常，表明转义失败
     */
    public static byte[] revert(byte[] raw) throws Exception {
        ByteBuffer temp = ByteBuffer.allocate(raw.length);
        for (int i = 0; i < raw.length; i++) {
            Byte b = raw[i];
            if (b == REVISE_CODE) {
                i++;
                byte type = raw[i]; // 此处发生越界异常
                if (type == REVISE_HEAD) {
                    temp.put(HEAD);
                } else if (type == REVISE_TAIL) {
                    temp.put(TAIL);
                } else if (type == REVISE_SELF) {
                    temp.put(REVISE_CODE);
                } else {
                    throw new RuntimeException("revert error!");
                }
            } else {
                temp.put(b);
            }
        }

        int ret_len = temp.position();
        byte[] ret = new byte[ret_len];
        temp.flip();
        temp.get(ret);
        return ret;
    }


    public int getCode() {
        if (0 == mCode) {
            mCode = CodeUtils.getCode();
        }
        return mCode;
    }

    public void setCode(int code) {
        mCode = code;
    }

    //--- 接收或者发送时间 ---
    private long time = System.currentTimeMillis();

    public void updateTime() {
        time = System.currentTimeMillis();
    }

    public long getTime() {
        return time;
    }
}
```

通过数据抽象处理后，其他的数据包就比较容易实现了，例如：

**心跳数据包：**

```java
public class GHeartPacket extends Packet {
    public static final byte FRAME_TYPE_HEART = (byte) 0x00;    // 心跳

    public GHeartPacket() {}

    public GHeartPacket(int code) { super(code); }

    @Override
    public byte[] getFrameBytes() {
        return packet(FRAME_TYPE_HEART, getCode(), null);
    }
}
```

**内容数据包：**

```java
public class GContentPacket extends Packet {
    public static final byte FRAME_TYPE_CONTENT = (byte) 0x01;  // 内容

    private byte[] content;

    public GContentPacket(byte[] data) {
        content = data;
    }

    public GContentPacket(@NonNull String str) {
        content = str.getBytes(Charset.forName("UTF-8"));
    }

    public GContentPacket(int code, byte[] data) {
        super(code);
        content = data;
    }

    public GContentPacket(int code, @NonNull String str) {
        super(code);
        content = str.getBytes(Charset.forName("UTF-8"));
    }

    @Override
    public byte[] getFrameBytes() {
        return packet(FRAME_TYPE_CONTENT, getCode(), content);
    }

    public String getContent() {
        if (null == content) return "";
        return new String(content, Charset.forName("UTF-8"));
    }
}
```

有了基础数据包之后，利用基础数据包提供的方法，再去封装其他的数据包就十分容易了，上面以两类数据包举例，可以拓展任何其他类型的数据包。

#### 3.2.3 数据包的编解码

**编码器：**

由于我们封装的 Packet 已经自带了编码功能，因此编码器就非常简单了，首先继承 `MessageToByteEncoder` 然后调用 packet 的  `getFrameBytes()` 方法就可以了。

```java
/**
 * 作用: TCP 数据帧编码器
 * 作者: GcsSloop
 */
public class TCPFrameEncoder extends MessageToByteEncoder<Packet> {
    @Override
    protected void encode(ChannelHandlerContext cxt, Packet in, ByteBuf out) throws Exception {
        out.writeBytes(in.getFrameBytes());
    }
}
```

**解码器：**

然而解码就比较麻烦了，不过根据协议一步步的处理也是可以的，解码主要有以下步骤：

1. 根据帧头和帧尾准确获得一帧的内容数据。
2. 判断内容数据长度是否符合要求。
3. 对内容数据进行反转义。
4. 进行 CRC 校验，确认内容完整性。
5. 对内容尝试进行分解(得到帧类型，确认码，数据)。
6. 将分解后的数据交给子类进行处理。

> 注意：一旦涉及到 TCP 传输数据，肯定绕不开 TCP 粘包和拆包问题，通常来说一个数据包使用一个 TCP 包来发送，发生粘包就是两个较小的数据包合并为一个 TCP 包同时发送，拆包则是一个较大的数据包被拆分为多个小的 TCP 包进行发送，如果对粘包和拆包问题处理不当，会导致数据解析出现问题。
>
> 不过拆包和粘包问题在这里是不会有影响的：  
> 第一，我们有明确的帧头和帧尾表明界限，解决了粘包问题。  
> 第二，Netty 默认已经处理了拆包问题，你可以注意一下 decode 中调用了 `skipBytes` 用于跳过已经处理过的数据，如果没有处理的数据在下次回调 decode 方法时还会存在。

```java
/**
 * 作用: 基础 TCP 数据帧解码器, 只对基本结构进行解析, 具体需要转换为什么类型,交由子类进行处理
 * 作者: GcsSloop
 * 摘要: 基本的帧结构
 * +----------+----------+--------------------------------------------------------
 * |  大小    |  固定值   |  摘要
 * +----------+----------+--------------------------------------------------------
 * | 1 bytes  | 0xC0     |  帧起始符
 * | 1 bytes  |          |  帧类型
 * | 4 bytes  |          |  确认码
 * | 4 bytes  |          |  内容长度
 * |          |          |  内容
 * | 2 bytes  |          |  校验码 CRC 校验
 * | 1 bytes  | 0xDE     |  帧结束符
 * +----------+----------+--------------------------------------------------------
 * 加密范围:帧类型+确认码+内容长度+内容.
 */
public abstract class BaseTCPFrameDecoder extends ByteToMessageDecoder {
    @Override
    protected void decode(ChannelHandlerContext channelHandlerContext, ByteBuf in, List<Object> list) throws Exception {
        ByteBuffer buffer = in.nioBuffer();
        byte temp;
        ByteBuffer frame = ByteBuffer.allocate(buffer.limit());

        while (buffer.position() < buffer.limit()) {
            temp = (byte) (buffer.get() & 0xFF);
            // 发现开始位置标识(尝试获取一帧的数据)
            if (temp == HEAD) {
                frame.clear();
                while (buffer.position() < buffer.limit()) {
                    temp = (byte) (buffer.get() & 0xFF);
                    if (temp != Packet.TAIL) {
                        frame.put(temp);
                    } else {
                        break;
                    }
                }
                // 如果 temp != TAIL, 说明该数据帧不是完整的，无需解析
                if (temp != Packet.TAIL) {
                    return;
                }

                // 说明该帧数据是完整的，可以尝试进行解析，此时 frame 中存储的是去除了帧头和帧尾的数据
                in.skipBytes(buffer.position());            // 跳过该帧内容

                // 在解析之前先进行反转义
                byte[] raw = new byte[frame.position()];
                frame.flip();                               // 切换到读取模式
                frame.get(raw);                             // 获取原始数据(frame中所有数据)
                frame.compact();                            // 将读取过的数据清除

                byte[] content = Packet.revert(raw);        // 获取反转义后数据
                frame.put(content);                         // 将反转义后数据依旧放入 frame 中

                // 长度校验
                if (frame.position() < 11) {                // 判断帧的长度是否足够，一帧必须包含帧类型，确认码，内容长度，CRC校验码，因此最少也需要 11 个 byte
                    System.out.println("frame length too short!");
                    return;
                }

                // CRC 校验
                if (!checkCRC(content)) {
                    System.out.println("CRC check error!");
                    return;
                }

                // TODO 输出内容信息
                System.out.println(b2h(content));

                frame.flip();
                byte frame_type = frame.get();              // 帧类型
                int frame_code = frame.getInt();            // 确认码
                int data_len = frame.getInt();              // 内容长度

                int need_len = data_len + 11;               // 有了内容长度，就可以得到该帧需要的长度
                if (frame.limit() != need_len) {         // 对帧长度进行严格校验
                    System.out.println("frame length error，real length = " + frame.position() + ", but need length = " + need_len);
                    return;
                }

                byte[] frame_data = new byte[data_len];
                frame.get(frame_data);                      // 帧内容

                Packet packet = decodeData(frame_type, frame_code, frame_data);
                if (null != packet) {
                    list.add(packet);
                }
            }
        }
    }

    /**
     * 检查内容区域是否符合 CRC 校验
     *
     * @param content 内容数据，不包括帧头和帧尾部
     * @return 校验结果，true 表示校验成功，false 表示校验失败
     */
    public static boolean checkCRC(byte[] content) {
        short crc_result = CRCUtils.getCRC(content, 0, content.length - 2);
        byte[] crc_raw = new byte[2];
        System.arraycopy(content, content.length - 2, crc_raw, 0, 2);
        short crc_short = BytesUtils.byteArrayToShort(crc_raw);
        return crc_result == crc_short;
    }

    /**
     * 解析内容数据, 只有通过了数据帧校验和 CRC 校验的数据才会被送到这里进行解析
     * 帧头, 帧尾, 校验码, 没有进行传递.
     *
     * @param frame_type 帧类型
     * @param frame_code 确认码
     * @param data       数据
     * @return 数据包
     */
    @Nullable
    public abstract Packet decodeData(byte frame_type, int frame_code, byte[] data);
}
```

基础解码器只是做到将数据分解成为原始数据，但是并没有转换为数据包，数据包最终转换需要交由其子类进行处理。

**服务端解码器：**

服务端解码器为基础解码器的子类，主要就是实现了将原始数据转换为数据包的过程。

```java
public class ServerTCPFrameDecoder extends BaseTCPFrameDecoder {
    @Override
    public Packet decodeData(byte frame_type, int frame_code, byte[] data) {
        if (frame_type == FRAME_TYPE_HEART) {
            return new GHeartPacket(frame_code);
        } else if (frame_type == FRAME_TYPE_22) {
            return new G22Packet(frame_code);
        } else if (frame_type == FRAME_TYPE_CONTENT) {
            return new GContentPacket(frame_code, data);
        }
        return null;
    }
}
```

**客户端解码器：**

客户端解码器同理。

```java
public class ClientTCPFrameDecoder extends BaseTCPFrameDecoder {

    @Override
    public Packet decodeData(byte frame_type, int frame_code, byte[] data) {
        if (frame_type == FRAME_TYPE_HEART) {
            GHeartPacket heart = new GHeartPacket(frame_code);
            return heart;
        } else if (frame_type == FRAME_TYPE_33) {
            G33Packet g33 = new G33Packet(frame_code);
            return g33;
        } else if (frame_type == FRAME_TYPE_CONTENT) {
            GContentPacket content = new GContentPacket(frame_code, data);
            return content;
        }
        return null;
    }
}
```

编解码器只是负责将数据包和数据流之间的相互转换，最终数据处理则是应该交由 Handler 进行处理。

#### 3.2.4 数据包的处理

**服务端处理：**

在这里，由于服务端是用来测试的，因此处理就比较简单了，数据在解码后会转换为对应的 Packet，而 Netty 会将 Packet 发送给对应的 Handler，Handler 收到数据后，将需要返回给客户端的内容发送出去就可以了。

```java
public class G22Handler extends SimpleChannelInboundHandler<G22Packet> {
    @Override
    protected void channelRead0(ChannelHandlerContext ctx, G22Packet g22) throws Exception {
        System.out.println("收到 22， 回复 33");
        G33Packet g33 = new G33Packet(g22.getCode());
        ctx.writeAndFlush(g33);
    }
}
```

> 例如： 2233 命令，当服务端收到 G22Packet 后，发送一个 G33Packet。

**客户端处理：**

**1. 客户端数据包的发送：**

客户端有一个数据发送队列，在服务开启时，会启动一个线程不断的查询队列中是否存在数据，如果存在数据就将数据发送出去：

```java
mWorkThread = new Thread(new Runnable() {
    @Override
    public void run() {
        try {
            // 连接服务
            future = boot.connect(host, port).sync();
            System.out.println("服务已启动!");
            mSendQueue.clear();

            while (true) {
                Packet packet = mSendQueue.take();
                if (packet instanceof ClosePacket) {
                    break;
                }
                // 发送
                future.channel().writeAndFlush(packet);
            }
            System.out.println("服务关闭!");
        } catch (InterruptedException e) {
            System.out.println("服务被强制关闭!");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
});
mWorkThread.start();
```

> 数据发送队列使用的 LinkedBlockingDeque 是一个双向队列，在轮训中使用了 take 方法来获取头部数据，而 take 方法在队列中没有数据时会阻塞，直到有新的数据进来，这样可以防止 while 循环空转，占用过高的 CPU 资源。
>
> 同时为了可以优雅的终止服务，设置了一个特殊的数据包 ClosePacket， 当该线程收到 ClosePacket 之后就会停止轮训，结束线程。

有了该轮训后，所有需要发送的数据只需丢入到发送队列中即可发送出去。

```java
public void sendPacket(Packet packet) {
    if (!isStart || null == mWorkThread) {
        System.out.println("服务未开启!");
        return;
    }
    try {
        mSendQueue.add(packet);
    } catch (Exception e) {
        e.printStackTrace();
    }
}
```

**2. 客户端数据包的接收**

数据包可以是单向发送的，即只有客户端发向服务端，或者只有服务端发给客户端，这样的单向数据后很好处理，只用转交给对应的 Handler 即可。

但是还有很多情况下数据传递是双向的，例如：客户端发送请求获取用户信息，服务端收到后将用户信息返回给客户端。双向数据传递就需要把服务端返回的数据返回给对应的调用者，为了可以分辨服务端返回的数据包属于哪一个调用者发送的，在每一帧的数据里面都有确认码，客户端发送时每一帧的确认码都不相同，而服务端收到后会在返回帧里面设置相同的确认码，这样在客户端收到服务端的回执数据后就可以通过确认码知道是哪一次调用的结果了。

首先，客户端收到服务端发送过来的消息后会先进行解码，之后交给 AckHandler，AckHandler 会把消息放到接收队列中。

```java
class AckHandler extends SimpleChannelInboundHandler<Packet> {

    @Override
    protected void channelRead0(ChannelHandlerContext cxt, Packet ack) throws Exception {
        //noinspection StatementWithEmptyBody
        if (ack instanceof GHeartPacket) {
            System.out.println("心跳正常.");
        } else {
            System.out.println("收到数据:" + ack.getClass().getSimpleName());
            mRecvQueue.put(ack);
        }
    }
}
```

如果想要获取对应的结果，则通过 getFilterPacket 方法来过滤接收队列中的内容：

```java
@Nullable
public Packet getFilterPacket(Filter filter, long timeout) throws InterruptedException {
    long starttime = System.currentTimeMillis();    // 记录开始时间
    Packet ret = null;
    // 在未超时的情况下不断尝试获取新数据
    do {
        // 计算新的 timeout
        long newtimeout = timeout - (System.currentTimeMillis() - starttime);
        if (newtimeout < 100) {
            newtimeout = 100;
        }
        Packet packet = mRecvQueue.pollLast(newtimeout, TimeUnit.MILLISECONDS);
        if (filter.accept(packet)) {
            // 获取到数据，直接跳出循环
            ret = packet;
            break;
        } else {
            // 将不需要的数据放回队列
            if (null != packet)
                mRecvQueue.putFirst(packet);
        }
        Thread.sleep(10);   // 默认休眠， 防止不断重复的取垃圾数据
    } while (System.currentTimeMillis() - starttime < timeout);
    return ret;
}
```

考虑到网络的不确定性，有时可能因为网络原因而无法收到回执结果，因此在获取过滤数据时是有超时设置的，一旦超过这个时限，如果依旧未获取到结果，则会返回 null。

但是这会导致另外一个问题的发生，如果服务端返回数据速度比较慢，在返回时，客户端读取早就已经超时了，那么这条数据就会变成垃圾数据堆积在接收队列中。为了避免垃圾数据堆积，我让其在空闲时清除接收队列中的超时数据。

```java
private void clearTimeoutPacket(IdleStateEvent evt) throws InterruptedException {
    if (evt.state() == IdleState.ALL_IDLE) {
        int size = mRecvQueue.size();
        for (int i = 0; i < size; i++) {
            Packet packet = mRecvQueue.pollFirst();
            if (null == packet) break;
            if (!isPacketTimeout(packet)) {
                mRecvQueue.putLast(packet);
            } else {
                //System.out.println("清理掉一条垃圾数据 队列大小 = " + mRecvQueue.size());
            }
        }
    }
}
```

#### 3.2.5 心跳逻辑

由于网络连接的不稳定性，为了可以与服务端保持长连接，需要设计心跳机制来保证连接的稳定性。这里的心跳逻辑非常简单，那就是在发生“写超时(即一段时间内没有向服务端发送任何数据)“的情况下向服务端发送一个心跳包。

```java
// 发送心跳
private void heartbeat(IdleStateEvent evt) {
    if (evt.state() == IdleState.WRITER_IDLE) {
        GHeartPacket mHeartBeat = new GHeartPacket();
        sendPacket(mHeartBeat);
    }
}
```

#### 3.2.6 自动重连

在服务端与客户端断开连接时，需要判断一下是用户断开了连接还是因为网络原因意外断开了连接。如果是意外原因，则会尝试进行重新连接：

```java
// 自动重试
private void autoRetryConnect() {
    Timer timer = new Timer();//实例化Timer类
    timer.schedule(new TimerTask() {
        public void run() {
            if (isConnected || isUserClose) {
                timer.cancel();
            } else {
                tryReconnectSync();
            }
        }
    }, 100, mHeartbeatTime);
}
```

## 4. 后记

限于文章篇幅，不可能将所有的内容都讲解到，在文章之外依旧有很多的知识需要学习，如果你对 Netty 尚不了解的话，推荐看一下 《Netty 官方文档》和《Netty实战》，或者在网上搜索一下 Netty 相关的知识，这将会有助于你理解本文的内容。同样，上文也只是展示了一些较为核心的内容，至于如何把这些内容串联起来，里面到底是用了那种设计思路和设计的细节，更推荐大家下载一下文章开头或者结尾的项目源码进行查看(如果是在公众号中看到这篇文章，可以点击查看原文，在原文中下载)，项目为 IntelliJ 项目，自己可以试运行一下，相信每个人都会有自己的理解和感悟。

最后，由于本文所做设计为示例性质，仅仅花费了一天的时间把想到的内容转换为代码实现，不可能面面俱到，只是把一些核心功能做出来，如果有什么疑惑可以在文末评论或者联系我的私人微信“GcsSloop”进行交流。

**[【本文示例源码下载】](http://android.demo.gcssloop.com/C0DE_Sample.zip)**