---
layout: post
category: GeBug
title: 雕虫晓技(七) 用旧Android手机做远程摄像头
tags: Android
keywords: Android, ip-webcam, lanproxy, 反向代理, 内网穿透
excerpt: 用旧手机做摄像头。
typora-root-url: ../../../Source
---

### 关于作者

GcsSloop，一名 2.5 次元魔法师。  
[微博](http://weibo.com/GcsSloop/home) | [GitHub](https://github.com/GcsSloop) | [博客](http://www.gcssloop.com/)

![](http://gcsblog.oss-cn-shanghai.aliyuncs.com/blog/2019-04-29-073235.jpg?gcssloop)

## 0. 前言

科技发展越来越快，手机也换的越来越频繁，有很多旧手机都被淘汰了，这些旧手机一般没什么用，也不能卖，毕竟手机中可能还存在着一些私人数据可能没有清空，因此这些旧手机就只能放在家里落灰了。

对于大多数人来说，这些旧手机都是无法被利用起来的，虽然网上有很多的利用旧手机的教程，但很多要么是很鸡肋，要么是操作难度较高，需要较强的动手能力。

那么今天呢，就教大家如何**低成本的快速将旧 Android 手机变成一个可远程访问的摄像头**。

本文定位是一个比较基础的教程，假设大家对这方面都不熟悉，所以文中啰嗦的内容比较多，有些技术点如果大家已经有所了解，可以跳过内容。

## 1. 搭建局域网摄像头

搭建局域网摄像头需要一个软件，那就是 ip-webcam，能访问谷歌商店的用户可以直接在商店内搜索 “ip-webcam” 下载即可，对于无法访问的用户可以到 https://www.appsapk.com/ip-webcam/ 进行下载。

> ip-webcam 是一款免费软件(免费版本存在广告)，它有一个付费的 pro 版本，pro版本功能更强，但只能在谷歌商店购买，如果想买但是没有可用的付款卡，可以使用礼品卡进行充值购买，礼品卡在淘宝有卖。但是对于普通用户来说，免费版已经足够了。

ip-webcam 的图标是这样的：

![IP-Webcam](/assets/gebug/07-internet-ip-webcam/IP-Webcam.jpg)

打开后里面大概这样子：

![webcam-show](/assets/gebug/07-internet-ip-webcam/webcam-show.png)

由于我们后面会把这个摄像头放到公网上，所以需要把设置一个账号密码，不然很不安全。但是如果只是需要在局域网使用的话，账号密码可以留空。

![webcam-config1](/assets/gebug/07-internet-ip-webcam/webcam-config1.png) ![webcam-config2](/assets/gebug/07-internet-ip-webcam/webcam-config2.png)

在配置完账号密码后，其他内容可以按照自己的需要进行调整，需要注意的是，如果家庭网络的上行带宽比较低的话，可以适当的把视频分辨率和帧率调低一点，否则在外网访问的时候会一直卡顿。

在设置完成后，翻到最后面一条，直接点击开启服务器即可。

![webcam-start](/assets/gebug/07-internet-ip-webcam/webcam-start.png)

在服务开启后，会在界面上显示视频的连接地址，如下：

![webcam-link](/assets/gebug/07-internet-ip-webcam/webcam-link.png)

如上图所示，上面的地址就是服务访问地址，在当前网络内任意电脑或者手机上输入该地址即可访问到摄像头，点击浏览器选项就可以看到视频的内容。

![webcam-watch](/assets/gebug/07-internet-ip-webcam/webcam-watch.png)

可以看到，它除了查看视频之外，还有很多功能，例如：动作检测(自动抓拍)，开关闪光灯，循环录制等。

还有更多的高级功能，例如配合 tasker 来开发更多功能，大家可以自行发掘。

**注意：**

用手机做摄像头，需要注意发热问题，部分手机因为设计问题，长期开启摄像头会导致手机发热严重，如果长时间发热可能会损坏设备，至于自己的设备是否适合做摄像头，可以自己先试验一下，一般来说，常温下运行一两个小时以上没有因为过热导致关机等问题就可以作为一直开启的摄像头来用。但是仍然需要注意不要放置于温度过高或者阳光直射的地方。

如果是一直开启则应该放置在电源附近，或者买一根比较长的数据线来为其充电。

## 2. 连接到公网

上面开启的摄像头只能在局域网使用，如果需要在公网使用，那么就稍微麻烦一点了。如果自己办理的宽带有静态的公网IP，那么可以在路由器上设置一下端口映射就可以在外网访问了。

但是大部分用户办理的宽带都是动态公网IP或者共享公网IP，那么设置端口映射就不管用了，因此就需要考虑一些其他方案。

### 2.1 免费方案

如果不想花钱，直接搜索动态域名解析、内网穿透就可以找到相关软件，有很多商业的软件可以用，例如：花生壳、nat123 等。这些商业软件都有详细的使用说明，我也就不再赘述了，有需要的可以自行搜索使用方案，对于动手能力不太强或者需求不大的用户来说，直接注册后使用免费套餐即可，相对来说安装更加简单。

但是免费一般会有很多的限制，例如流量限制，映射条数限制，域名限制等。并且一般还需要实名认证。因此个人试用过一段时间这种方案后，觉得用着很不舒服，于是也就放弃了。

### 2.2 极客方案

**首先声明，这种方案并非免费，但是所有的内容都可以掌控在自己手里，如果仅仅只是需要一个家庭摄像头的话，又不想花太多钱，直接去淘宝买一个成品带服务或许更便宜一点。**

(由于家庭摄像头拍摄位置可能会涉及到隐私区域，因此个人对部分商业摄像头直接把非加密视频数据上传到公司服务器上是十分不信任的，除此之外，很多商业摄像头为了方便远程调试安装，都留有一定的远程控制方案，我相信商业公司员工不会私自查看视频信息，但是这种方式会给一些居心不良的黑客留下可乘之机，因此我自己搭建了一套服务。)

我使用的这种方案需要一个公网服务器作为代理，因为服务器不承载主要的运算服务，只是做流量转发，所以不需要很高的性能，也不需要大量的存储空间，我自己目前使用的是1核1G的乞丐级配置，在阿里云上租用一年300多。当然，部分国外的服务器会更加便宜，例如我在其他平台上租用的美国服务器，一年服务费用大约200多元，赶上促销的话，不到100元就能租用一年的服务，但是由于是做流量转发的，自己又主要在国内活动，国外的服务器延迟稍微有点大，因此就买了比较贵的阿里云服务。需要注意的是，如果不想备案的话，可以买香港服务器，当然国外的cn2也是可以接受的。

最重要的是，一台服务可以做的事情很多，包括但不限于以下事情：私有云盘、个人网站、Git仓库、代理服务、游戏服务器、下载服务、爬虫。

#### 2.2.1 实现原理

上面说了一大堆乱七八糟的东西，下面先说一下这种方案的原理：

原理其实非常简单，就是一个反向代理服务，用一台公网的代理服务器(proxy-server)作为跳板，可以从公网上任意位置访问这个服务器，之后这个服务器会把接收到的信息转发给对应的代理客户端(peoxy-client)，由代理客户端去访问处于内网的服务，内网服务响应后，按照相反的路径传递回去，最终就可以实现从任意位置访问到内网的服务啦，原理图如下：

![lanproxy](/assets/gebug/07-internet-ip-webcam/lanproxy.png)

> 图片来自： [lanproxy](https://github.com/ffay/lanproxy/blob/master/README_en.md)

#### 2.2.2 实现方案

我在GitHub上找到了一个开源的反向代理工具，这个工具有打包好的版本，并且部署非常简单，它就是 lanproxy。

GitHub 地址： https://github.com/ffay/lanproxy

>  lanproxy是一个将局域网个人电脑、服务器代理到公网的内网穿透工具，目前仅支持tcp流量转发，可支持任何tcp上层协议（访问内网网站、本地支付接口调试、ssh访问、远程桌面...）。目前市面上提供类似服务的有花生壳、TeamView、GoToMyCloud等等，但要使用第三方的公网服务器就必须为第三方付费，并且这些服务都有各种各样的限制，此外，由于数据包会流经第三方，因此对数据安全也是一大隐患。 [https://lanproxy.io2c.com](https://lanproxy.io2c.com/)

#### 2.2.3 下载软件

到 [lanproxy-releases](https://seafile.io2c.com/d/3b1b44fee5f74992bb17/) 下载打包好的服务端和客户端。

![download-server](/assets/gebug/07-internet-ip-webcam/download-server.png)

#### 2.2.4 上传服务端到自己的服务器

我自己使用的是阿里云的服务器，CentOS 7.4 系统，因此就以此系统为基准做介绍，当然，其他的系统也是支持的(包括各类Linux和WIndows)。

这里需要注意的是，此处需要熟悉一些基础的 linux 相关命令，假设大家都会一点基础的 Linux 命令。

如果大家对 vi(vim) 等文本编辑命令熟悉的话，直接上传原始server端压缩包到服务，解压后通过这些命令对配置文件(proxy-server-20171116/conf/config.propertoes)进行编辑即可。

如果不熟悉 linux 上文本编辑相关命令，可以现在自己电脑上解压，找到对应的配置文件(proxy-server-20171116/conf/config.propertoes) 进行编辑，之后再次压缩进行上传到服务器也可以。

默认的配置文件如下：

```properties
server.bind=0.0.0.0
server.port=4900

server.ssl.enable=true
server.ssl.bind=0.0.0.0
server.ssl.port=4993
server.ssl.jksPath=test.jks
server.ssl.keyStorePassword=123456
server.ssl.keyManagerPassword=123456
server.ssl.needsClientAuth=false

config.server.bind=0.0.0.0
config.server.port=8090
config.admin.username=admin
config.admin.password=admin
```

**注意：修改 username 和 password 字段。**

之后通过 `scp` 命令将服务端上传到服务器：

```shell
scp local_file remote_username@remote_ip:remote_folder

# 例如
scp lanproxy-server-20171116.zip root@12.34.56.78:/home/lanproxy
```

#### 2.1.3 安装基础工具

使用 ssh 命令登陆服务器，阿里云可以直接在网页登陆，其他服务器使用ssh命令登陆即可。

```shell
# 登陆到服务器
ssh root@ip
# 输入密码，密码从购买服务器的平台获取，输入密码时不会显示任何字符，输入完成后直接点击回车键就可以了。
```

如果你的服务上没有zip软件解压工具，可以通过下面的命令安装：

```shell
yum install zip unzip
```

除了这些工具外，还需要安装 java 运行环境，直接安装 openjdk就可以了，1.7 或者 1.8 版本都可以。

```shell
yum install java-1.7.0-openjdk.x86_64
```

安装完成后解压软件：

```shell
unzip lanproxy-server-20171116.zip
```

#### 2.2.5 启动服务

到解压后文件夹中的 bin 目录下，执行启动命令：

```shell
./startup.sh
```

如果启动成功，它会显示一个 pid，例如：

```shell
./startup.sh 
Starting the proxy server ...started
PID: 19875
```

到这里，服务就正式启动了，后续的内容可以到网页上进行设置，访问 `http://IP:8090` 就能看到管理页面了(IP是服务器的公网IP)。

> PS：如果无法访问到，请检查是否可以 ping 通该端口，服务器的防火墙，和阿里云的安全组规则。

登陆页面如下：

![lanproxy-login](/assets/gebug/07-internet-ip-webcam/lanproxy-login.png)

用之前配置的用户名和密码进行登录，登陆后添加一个客户端，如下，名称随便写，密钥用随机生成的即可。

![lanproxy-add-client](/assets/gebug/07-internet-ip-webcam/lanproxy-add-client.png)

之后你会看到在配置管理里面多了一个条目 G-IPCam, 点击该条目然后点击添加配置进行添加端口映射(添加一条摄像头的映射，后端代理信息就填写之前摄像头上显示的 IP 地址)：

![lanproxy-add-config](/assets/gebug/07-internet-ip-webcam/lanproxy-add-config.png)

![lanproxy-fill-config](/assets/gebug/07-internet-ip-webcam/lanproxy-fill-config.png)

点击提交后，一条映射数据就被添加上去了。

**注意：**

如果使用的是阿里云服务器，要设置安全组配置来开放 8080 端口，如果是其他平台的服务器，则要设置防火墙来开放端口，具体设置方法需要根据服务器系统类型来设置，可以自己搜索。

#### 2.2.6 客户端连接

**使用局域网内的任意一台主机作为跳板连接公网代理服务器。**

**下面这一段取自 lanproxy 说明文档。**

到上面为止，服务端已经搭建完成了，只要客户端连接成功就可以通过互联网进行访问了，在手机所在的局域网内的任意电脑主机上安装客户端(client)，在上面下载的发布包中有基于java的跨平台客户端，配置方式如下：

> Java client的配置文件放置在conf目录中，配置 config.properties

```
#与在proxy-server配置后台创建客户端时填写的秘钥保持一致；
client.key=
ssl.enable=true
ssl.jksPath=test.jks
ssl.keyStorePassword=123456

#这里填写实际的proxy-server地址；没有服务器默认即可，自己有服务器的更换为自己的proxy-server（IP）地址
server.host=lp.thingsglobal.org

#proxy-server ssl默认端口4993，默认普通端口4900
#ssl.enable=true时这里填写ssl端口，ssl.enable=false时这里填写普通端口
server.port=4993
```

- 安装java1.7或以上环境
- linux（mac）环境中运行bin目录下的 startup.sh
- windows环境中运行bin目录下的 startup.bat

如果不想安装Java环境，可以直接运行该平台编译好的client。

###### 普通端口连接

```
# mac 64位
nohup ./client_darwin_amd64 -s SERVER_IP -p SERVER_PORT -k CLIENT_KEY &

# linux 64位
nohup ./client_linux_amd64 -s SERVER_IP -p SERVER_PORT -k CLIENT_KEY &

# windows 64 位
./client_windows_amd64.exe -s SERVER_IP -p SERVER_PORT -k CLIENT_KEY
```

###### SSL端口连接

```
# mac 64位
nohup ./client_darwin_amd64 -s SERVER_IP -p SERVER_SSL_PORT -k CLIENT_KEY -ssl true &

# linux 64位
nohup ./client_linux_amd64 -s SERVER_IP -p SERVER_SSL_PORT -k CLIENT_KEY -ssl true &

# windows 64 位
./client_windows_amd64.exe -s SERVER_IP -p SERVER_SSL_PORT -k CLIENT_KEY -ssl true
```

如果没有错误出现的话，连接成功后，在网页上可以看到客户端的连接状态变成了在线，如下：

![lanproxy-status](/assets/gebug/07-internet-ip-webcam/lanproxy-status.png)

可以看到，上面的客户端有一个是连接状态，另一个是离线状态。

#### 2.2.7 在公网查看

如果上述步骤均正常，最后客户端显示在线状态就可以到网页上查看摄像头了，访问 http://proxy-server-ip:8080 (例如:http://12.34.56.78:8080) 看是否显示正常。

正常的话就会显示如下界面：

![webcam-watch](/assets/gebug/07-internet-ip-webcam/webcam-watch.png)

如果无法正常显示，请依次检查如下问题：

1. 检查服务器是否可以 ping 通。
2. 检查 lanproxy

#### 2.2.8 独立摄像头

在上面摄像头和公网服务器之间通信使用了一台局域网内的主机作为跳板，需要一只处于开启状态才能保证摄像头的连接正常，但是这样会引起一些其他问题，例如主机风扇噪音过大，比较耗电等，我们毕竟只是需要一个小小的中转服务，这样就会显得比较浪费了。之前为了解决这个问题，准备买一个树莓派来作为局域网内流量中转设备，毕竟树莓派功耗相对于个人PC来说要小很多，并且更加安静。

后来发现meefik大神开发了相关的应用，可以直接在 Android 设备上部署 Linux 系统，于是想，既然可以部署 Linux 系统，那么岂不是可以在摄像头所在手机上直接进行流量中转了？于是又折腾了一下，最终证实方案可行，但是过程却是比较麻烦，下面分享一下主要的过程。

1. 获取 root 权限。
2. 安装 busybox
3. 安装 linux deploy

虽然步骤看似简单，但是坑确实超多，随着 Android 系统越来越完善，在大部分情况下已经不需要 root 了，导致很多 root 工具都无法使用了，在试用了几乎所有的root工具后，最后还是靠刷机获取的 root 权限，我用的设备是华为旧手机，先去官网申请解锁 bootloader，然后刷入第三方的 Recovery，最后在网上找到一个自带root权限的系统刷入进去，需要注意的是，如果是主力机，目前还是不要刷机了，因为现在在网络上可以找到的刷机包，基本都捆绑了一些垃圾应用，哪些搞纯净包的因为没法盈利，大部分早就不更新了，所以刷机需谨慎。

当然，如果是手机已经基本不用了，那随便折腾都行，不过刷机后记得第一时间卸载掉所有的垃圾应用，我使用的是Es文件浏览器，借助它的root工具箱卸载掉位于系统中的垃圾应用，卸载完成后重启一下设备。

如果正常获取了 root 权限，后续就比较简单了。到 [Github·Busybox](https://github.com/meefik/busybox/releases) 下载apk文件，之后安装到手机中，如果 bubsybox 申请 root 权限，点击允许即可。

之后到 [Github · linuxdeploy](https://github.com/meefik/linuxdeploy/releases) 下载文件，同样安装到手机中，如果需要安装对应版本 的系统，可以在网络上搜索相关的教程，例如 "linux deploy 安装 CentOS"，由于教程过长，这里就不过多叙述了。

系统安装完成后，同样利用 scp 命令把对应的 client 长传到系统中，例如我安装了一个 kail 系统，架构是 armv71，需要上传 `client_linux_arm7` 这个文件，完成之后使用 ssh 登陆进系统，按照上一步的方式启动服务，如果在网页上可以看到状态为在线，那么就说明可以正常使用了，后续的操作步骤和前面两步的一致。

使用这种方式可以省掉一个中转用的PC，在同一台手机上开启摄像头，并且直接在这台手机上可服务器连接，更加省电，也避免了主机噪音。

## 3. 其它 

如果你有自己的域名的话，可以把服务器IP绑定到自己的域名上，方便记忆地址。

有部分服务器只允许开启80端口，对于这种情况，可以使用nginx或者配合lanproxy作者的另一款软件[proxygateway](https://github.com/ffay/proxygateway) 把其他端口的服务转发到80端口。例如：远程摄像头服务被代理到了 8080 端口，我们访问需要通过这个链接来访问： gcssloop.com:8080，但是8080端口被封闭了，导致无法访问，此时通过nginx进行端口转发，配置cat.gcssloop.com转发到8080端口。

```json
server {
    listen 80;
    server_name cat.gcssloop.com;
    location / {
        proxy_pass http://localhost:8080;
    }
}
```

我们可以通过访问 cat.gcssloop.com，来查看摄像头了。

如果你有多个摄像头，按照上面这种方式配置就可以通过不同的域名来访问不同的摄像头了，例如：room.gcssloop.com(室内)，door.gcssloop.com(门口)，而不用去记哪些烦人的端口地址。

## 4. 后记

使用这种方案部署摄像头基本上不用写代码，只用按照固定的格式来填一些配置文件就可以了，因此并不需要对编程方面有多么深入的了解，唯一比较麻烦的可能就是服务器的选取，和一些linux相关指令了，相信看这篇文章的人都对linux有所了解，即便没有多少了解，学习起来也是很容易的，毕竟此处能用到的指令就那么几个常用的，即便不会，花一两个小时学一下也是不亏的。

**如果喜欢的话，欢迎打赏赞助一些服务器费用。**

#### **关于作者**

GcsSloop，一名 2.5 次元魔法师。



