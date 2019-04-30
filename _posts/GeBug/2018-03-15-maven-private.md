---
layout: post
category: GeBug
title: 雕虫晓技(四) 搭建私有Maven仓库(带容灾备份)
tags: Android
keywords: Android
excerpt: 搭建供Android组件使用的私有maven仓库。
typora-root-url: ../../../Source
---

### 关于作者

GcsSloop，一名 2.5 次元魔法师。  
[微博](http://weibo.com/GcsSloop/home) | [GitHub](https://github.com/GcsSloop) | [博客](http://www.gcssloop.com/)

![](http://gcsblog.oss-cn-shanghai.aliyuncs.com/blog/2019-04-29-073231.jpg?gcssloop)

### 0. 前言

随着 Android 开发的发展，Android 开发也相对越来越简单，很多基础库只用简单的添加一行依赖就可以使用了，不用自己去手动添加，升级也只需要修改一下版本号，简单便捷。那么它是如何实现的呢？事实上，我们所依赖的这些文件，是存放在一些公开仓库中的，当我们添加这些依赖时，Gredle 会自动去仓库中查找是否存在，如果存在，就下载下来放到本地参与编译。

我们最常用的一些公开库大部分是放在 jcenter 仓库中的，我们在创建项目的时候会默认添加 jcenter 仓库，在项目的 build.gradle 文件中可以看到，如下：

```groovy
allprojects {
    repositories {
        jcenter()
    }
}
```

但是，当我们自己开发的一些基础组件，也想要这样方面的添加到项目中时，就有点麻烦了，我们可以使用 [bintray](https://bintray.com/) 把这些组件上传到 jcenter 上面，但是上传过程非常麻烦，有一定的审核周期，并且一旦通过几乎无法撤销。

除了 jcenter 这个官方使用的仓库，[jitpack](https://jitpack.io/) 也是不错的选择，它借助于 GitHub 进行上传，上传和配置过程都有极大的简化，并且没有审核周期，很多公开项目都转用 jitpack 了。

但是，**公开仓库仅适合托管一些公开的内容，假若这些库涉及到部分商业机密，或者存在某些私密技术方案，不希望被竞争公司了解，那么托管在公开仓库上无疑是非常不合适的。**

**为了解决这些需求，自然就会有私有仓库的诞生，相信有不少公司都有自己的私有仓库。**
**如何搭建一个私有仓库网络上有大量的教程，也并不困难，但是重点是如何保证私有仓库的安全稳定却是一个大问题。**
如果仓库出现问题，则可能会导致所有的项目都无法 build 通过，会浪费大量的开发时间。

因此，在搭建一个私有仓库时，就必须要考虑到风险问题。下面我们就从头开始搭建一个仓库，并将教大家如何规避一些常见的风险。

### 1. 仓库搭建

我们 Android 使用的是 maven 仓库，关于私有的 maven 仓库，有很多集成好的仓库环境，甚至你可以不借助任何环境自己手动维护一个仓库。当然，手动维护仓库需要耗费非常多的时间和精力，对于普通的开发人员来说，是得不偿失的，毕竟时间就是金钱，因此我们使用集成好的仓库环境，例如本文中会用到 Sonatype 的 Nexus。

#### 1.1 Java环境

要运行 Nexus，需要 Java 环境，根据教程进行 [Oracle Java 安装和配置](https://www.java.com/zh_CN/download/help/download_options.xml) 即可，配置好环境就可以进行下一步了。

#### 1.2 下载

到 Sonytype 官网 https://www.sonatype.com/download-oss-sonatype 下载自己所需的平台和版本。

![01-download](/assets/gebug/04-maven-private/01-download.png)

直接下载对应平台的版本即可。

下载后解压到合适的目录，无需安装，可以看到两个文件夹(所有平台的都一样)，如下:

![02-Sonytype目录](/assets/gebug/04-maven-private/02-Sonytype目录.png)

| 目录           | 备注                                                         |
| -------------- | ------------------------------------------------------------ |
| nexus-x.x.x-xx | 这个文件夹是存放应用程序的。                                 |
| sonatype-work  | 这个文件夹是存放仓库和设置等相关内容的，**如果备份数据，只用备份这个文件夹即可**。 |

初次配置，我们只用关注如下几个文件即可：

| 文件                                          | 备注     |
| --------------------------------------------- | -------- |
| ./nexus-3.8.0-02/bin/nexus                    | 运行程序 |
| ./nexus-3.8.0-02/bin/nexus.rc                 | 用户配置 |
| ./nexus-3.8.0-02/etc/nexus-default.properties | 端口配置 |

初期需要了解的文件就这三个，在 Linux 系统上使用 root 用户直接运行可能会警告，因此可以配置一下nexus.rc文件。至于端口号，默认是 8081，如果对这个没特殊要求，默认即可。

**至于 ./nexus-3.8.0-02/bin/nexus 是主要的运行程序，建议将 bin 目录配置到环境变量中，这样就可以在任意位置启动和停止该程序了，否则只有在 bin 目录下才能调整。**

Window 版本是 **./nexus-3.8.0-02/bin/nexus.exe**  不过用法是一样的。

#### 1.3 运行

在命令行工具中输入启动命令：

```shell
nexus start
```

如果一切顺利，在等待几十秒到一两分钟之后就可以查看我们的仓库了，如果出错了，可以使用 run 命令来查看具体的出错原因：

```shell
# run 命令相当于 debug 模式，会输出所有的日志信息
nexus run
```

当然，Nexus 还有很多其他命令(例如:停止、重启、查看状态等)：

```shell
nexus {start|stop|run|run-redirect|status|restart|force-reload}
```

#### 1.4 查看

在输入 `nexus start` 命令后，稍微等待一两分钟，就可以查看仓库了，如果在本机有图形化界面，直接在浏览器中输入 `http://localhost:8081` 即可查看，如果修改了端口号，后面写对应的端口号即可。如果是运行在服务器上，则在其他电脑上输入`http://{服务器ip}:{port}` IP 和对应的端口号。如果运行成功，则会看到类似如下界面：

![03-nexus](/assets/gebug/04-maven-private/03-nexus.png)

**备注：**

- 在 Linux 和 Mac 上通过 `ifconfig` 查看本机 IP。
- 在 Windows 上通过 `ipconfig` 查看本机 IP。
- 127.0.0.1(localhost) 是本机回环地址，在其他机器上访问时不要使用这个地址。

### 2. 仓库配置

经过上面的步骤，我们就有了一个空仓库，但是这个仓库还还需要进行一些基础的配置。

#### 2.1 账号配置

##### 2.1.1 点击界面右上角的 **Sign In** 进行登录。

**初次登陆时使用默认账号：admin，密码：admin123。**

![04-signin](/assets/gebug/04-maven-private/04-signin.png)

##### 2.1.2 登陆后创建一个新用户

![05-create-user](/assets/gebug/04-maven-private/05-create-user.png)

##### 2.1.3 填写用户信息

![06-create-user-info](/assets/gebug/04-maven-private/06-create-user-info.png)

填写具体的用户信息，其中比较重要的部分已经用红字标记出来了。

**注意：**

- 注意用户权限，默认应该是有两个权限，管理员权限和所有用户(包括未登录用户)权限。
- Roles 左侧为目前的权限组，右侧为当前用户拥有的权限组，可以通过 [>] 和 [<] 按钮来调整用户权限。
- **在创建完新的用户后记得删除最初的管理员账号或者修改管理员账号的密码。**
- **用户所拥有的权限，是根据其拥有的权限组决定的，只要拥有 nx-admin 权限组，就拥有所有的管理权限，要注意该权限的分配。**

#### 2.2 创建仓库

仓库也是在设置中进行创建的，如下：

![07-create-repository](/assets/gebug/04-maven-private/07-create-repository.png)

![08-create-repository2](/assets/gebug/04-maven-private/08-create-repository2.png)

**我们用 maven 仓库即可，可以看到，仓库主要有三种类型：**

- **hosted：** 本地仓库，我们一般使用这种类型的仓库。
- **proxy：** 代理仓库，用于代理其他远程仓库。
- **group：** 仓库组，用来合并多个 hosted / proxy 仓库。

在一般情况下，我们创建 hosted 类型的 maven 仓库。

**填写仓库信息**

![09-create-repository3](/assets/gebug/04-maven-private/09-create-repository3.png)

如果没有特殊需求，直接填写一个名称然后点击创建即可。

**注意：**

- **Version policy(版本模式)** 有三种模式 Release(发布)、Snapshot(快照)、Mixed(混合)。
- **Layout policy(布局模式)** 有两种模式 Strict(严格模式)、Permissive(宽松模式)。
- **Deployment policy(部署模式)** 有三种模式 Allow redploy(允许重新部署)、Disable redploy(不允许重新部署)、Read-only(只读)。

一般情况下按照默认配置即可，需要注意的是，部署策略一般情况下请使用默认配置 **Disable redploy(不允许重新部署)**，例如，v1.0.0 版本的组建上传后，修改后再次以 v1.0.0 版本进行上传会上传失败，这样可以保证版本上传后不会被误覆盖掉，如果确定之前 v1.0.0 版本是错误上传的，需要重新上传，可以手动删除后再次上传，这样是最稳妥的。

在创建完成后就可以在仓库列表中查看到新创建的仓库了。

![10-new-repository](/assets/gebug/04-maven-private/10-new-repository.png)

#### 2.3 用户权限配置

用户权限配置相对来说稍微复杂一点，如果开发人员较少，又都是老手，不会存在小白删库的情况下，可以给所有人都分配一个管理账号或者共用一个管理员账号即可。

如果开发人员众多，又比较复杂，则需要仔细的控制每一个用户的权限，**一般来说，给普通用户分配公共仓库的查看、上传、读取的权限，不要给编辑和删除的权限。** 下面就带大家了解一下权限的详细设置方式：

Nexus 默认就有一个游客账号(anonymous)，在默认状态下拥有浏览所有仓库的权限，即在不登陆的情况下，可以查看所有仓库。

![11-User-Anonymous](/assets/gebug/04-maven-private/11-User-Anonymous.png)

该账号的权限分配十分重要，它意味这赋予所有未登录用户的权限，如果将管理员权限分配给了该账号，就意味着所有未登录用户都可以使用管理员权限，如果没有特殊情况，不要随意修改该账号的默认权限。

如果你不希望未登录用户查看，可以选择取消启用未登录账号，如下：

![12-Disable-Anonymous](/assets/gebug/04-maven-private/12-Disable-Anonymous.png)

然而，**如果我们希望游客可以查看和使用一部分仓库，另外部分仓库又不希望被未登录用户看到，那么就需要详细进行设置了。**

既然要修改权限，就要了解 Nexus 的权限管理方式，首先与权限有关的有如下几种：

![13-Sceurity](/assets/gebug/04-maven-private/13-Sceurity.png)

它们的关系如下：

![14-Nexus权限结构](/assets/gebug/04-maven-private/14-Nexus权限结构.jpg)

> **注意：**
>
> 1. 用户是通过持有不同的角色(权限组)来确定自己的权限管理范围的。
> 2. 角色(权限组)可以由基础权限和其他基础权限组来构成。

上面是 Nexus 支持的权限构成方式，在一般情况下我喜欢按照下面这种方式组织自己的权限。

![15-角色分组](/assets/gebug/04-maven-private/15-角色分组.jpg)

我把用户分为四类(超级管理员、仓库管理员、普通用户、游客)，并创建了四种类型的角色(权限组)，分别与之对应，这样在添加新用户的时候只需要赋予他对应的角色(权限组)即可。

##### 2.3.1 游客权限配置

**创建角色(权限组)**

![16-create-role](/assets/gebug/04-maven-private/16-create-role.png)

**创建游客角色**

其他的角色(权限组)也按照该方式进行创建即可，假设我们想把 gcssloop-central 这个仓库作为公开仓库，将这个仓库的查看和读取权限给予游客角色。

![17-role-anyone](/assets/gebug/04-maven-private/17-role-anyone.png)

**赋予游客用户权限**

![18-anyone](/assets/gebug/04-maven-private/18-anyone.png)

基础的设置方式就如上所示，只是不同的用户角色，拥有不同的权限而已。

##### 2.3.1 普通用户权限配置

![18-1-normal-user](/assets/gebug/04-maven-private/18-1-normal-user.png)

##### 2.3.1 管理员权限配置

![18-2-manager](/assets/gebug/04-maven-private/18-2-manager.png)

上面是一些常见的权限分配，比较粗略，如果有需要的话，可划分的更加细致，在创建完角色(Role)后，把对应的角色分配给对应的用户，该用户便可以获得对应的权限，超级管理员的角色(nx-admin)是默认就有的(拥有所有仓库的管理权限，以及修改设置的权限等)，它无需自己配置权限内容，只用分配给超级管理员用户使用即可。

### 3. 仓库备份

为了保证数据的安全，一定要对仓库数据进行备份，这样在出现意外情况的时候可以快速的恢复仓库状态，将影响降到最低。

#### 3.1 单仓库备份方案

仓库备份其实很简单，**Nexus 的所有信息都存储在 sonatype-work 文件夹中，单一仓库需要定时的备份该文件夹，一天至少备份一次以上，在服务器上运行的可以自己弄一些定时脚本来帮助自动化备份。**

恢复备份需要先关闭 nexux，让备份目录覆盖当前工作目录，之后重新启动 nexus 即可。

#### 3.2 多仓库同步方案

可以在多个的电脑(服务器)上搭建多个相同版本的仓库，以其中一个为主仓库，定时同步 sonatype-work 文件夹到其他备份仓库。

#### 3.3 多仓库同时上传

在拥有多个仓库的情况下，可以在上传脚本中配置多个仓库的上传方案，这样在发布的时候，分别发布到不同的仓库中，脚本的详细信息见下文。

#### 3.4 多仓库部署方案

**我自己使用的是多仓库方案，同时部署多个仓库，这样在其中一个仓库出现问题的时候迅速切换到其他仓库，可以在不影响开发的情况下对该仓库进行修复。**

**个人建议，直接把三个平台(Windows、Linux、OSX)的对应的同一版本都下载保存下来，这样方便以后部署，防止因为版本不同导致出现问题。**

我自己在内网服务器(Winsows Server)上部署了一套系统，公网服务器(Linux)上部署了一套系统，又在自己的个人电脑(OXS)上部署了一套系统，也算是在所有平台上都部署过了，部署过程大致上是相同的，具体可以见上文。

如果是多仓库部署的话，首先要部署并设置好一个仓库，之后部署时直接将设置完成仓库的 sonatype-work 文件夹复制后后续的部署平台上，这样就可以避免重复的设置，所有仓库的设置就可以保证是一致的。

我自己使用的是多个仓库，并绑定了域名解析，这样在一个仓库出现问题的时候，只用将域名暂时解析到正常的仓库即可。

### 4. 上传脚本

一个基础的上传脚本可以这样写，该上传脚本定义了三种基本行为：

1. 生成 doc 文档(该文档会上传到仓库上)
2. 上传到本机仓库，上传到公网仓库(如果你有更多仓库，同样可以仿照下面的方式配置上传信息)
3. 本地打包源码(本地的项目源码备份)，本地备份建议配合git使用。

```groovy
// pack-upload.gradle

// 指定编码
tasks.withType(JavaCompile) {
    options.encoding = "UTF-8"
}

// 打包源码
task sourcesJar(type: Jar) {
    from android.sourceSets.main.java.srcDirs
    classifier = 'sources'
}

task javadoc(type: Javadoc) {
    failOnError  false
    source = android.sourceSets.main.java.sourceFiles
    classpath += project.files(android.getBootClasspath().join(File.pathSeparator))
    classpath += configurations.compile
}

// 制作文档(Javadoc)
task javadocJar(type: Jar, dependsOn: javadoc) {
    classifier = 'javadoc'
    from javadoc.destinationDir
}

artifacts {
    archives sourcesJar
    archives javadocJar
}


apply plugin: 'maven'

// 对应的仓库地址
def URL_PUCBLIC = "http://lib.gcssloop.com:8081/repository/gcssloop-central/"
def URL_LOCAL = "http://localhost:8081/repository/gcssloop-central/"

// 上传到公共仓库
task uploadToPublic(type: Upload) {
    group = 'upload'
    configuration = configurations.archives
    uploadDescriptor = true
    repositories{
        mavenDeployer {
            repository(url: URL_PUCBLIC) {
                authentication(userName: USERNAME, password: PASSWORD)
            }
            pom.version = VERSION
            pom.artifactId = ARTIFACT_ID
            pom.groupId = GROUP_ID
        }
    }  
}

// 上传到本机仓库
task uploadToLocal(type: Upload) {
    group = 'upload'
    configuration = configurations.archives
    uploadDescriptor = true
    repositories{
        mavenDeployer {
            repository(url: URL_LOCAL) {
                authentication(userName: USERNAME, password: PASSWORD)
            }
            pom.version = VERSION
            pom.artifactId = ARTIFACT_ID
            pom.groupId = GROUP_ID
        }
    }  
}

// 压缩生成归档文件
task pack(type: Zip) {
    group = 'pack'
    archiveName = rootProject.getRootDir().getName() + "_v" + VERSION + ".zip";
    destinationDir = rootProject.getRootDir().getParentFile();
    from rootProject.getRootDir().getAbsolutePath();
    exclude '**.zip'
    exclude '**.iml'
    exclude '**/**.iml'
    exclude 'build/**'
    exclude '.idea/**'
    exclude '.gradle/**'
    exclude 'gradle/**'
    exclude '**/build/**'
}
```

**上面脚本文件中所需的仓库地址可以从下面这个地方获得：**

![18-0-maven-url](/assets/gebug/04-maven-private/18-0-maven-url.png)

**你可以把这份文件放置到任何地方，项目中、本地的指定位置、甚至是网络上，这样在使用的时候只需要添加一下引用即可。**

使用的时候如下(我把该文件放置在了自己电脑的桌面上)，在需要上传的 Library 的 build.gradle 中引用该文件并配置：

```groovy
// 配置上传信息
ext {
    USERNAME = "GcsSloop"
    PASSWORD = "xxxxxxx"
    GROUP_ID = "com.gcssloop.demo"
    ARTIFACT_ID = "uploader"
    VERSION = "1.0.0"
}

// 引用上传脚本
apply from: "/Users/gcssloop/Desktop/pack-upload.gradle"
```

![19-config](/assets/gebug/04-maven-private/19-config.png)

在配置完善后同步一下项目，就可以打开 gradle 命令菜单看到多出来了3个命令，双击即可执行对应的命令：

- pack：打包项目
- uploadToLocal：上传到本机仓库
- uploadToPublic：上传到公网仓库

![20-command](/assets/gebug/04-maven-private/20-command.png)

如果一切配置正确的话，等上传成功就可以在对应的仓库中看到上传的文件了。

![21-upload-over](/assets/gebug/04-maven-private/21-upload-over-0156932.png)

#### 注意：

**1. 如非必要尽量不要去删除已发布的Library，如果发现Library有bug，请修复后更新版本号重新发布。**

**2. 仓库默认不允许重新发布，若有更新，请修改版本号后再进行发布。**

### 5. 依赖配置

#### 5.1 添加仓库地址

在需要使用该 Library 的项目的根 build.gradle 中配置仓库地址(例如)：

```Groovy
allprojects {
    repositories {
        jcenter()
        maven {
            // 配置用户名和密码
            credentials { username 'GcsSloop' password 'xxxxxx' }
            // 配置仓库地址（获取方式见上文）
            url "http://localhost:8081/repository/gcssloop-central/"
        }
    }
}
```

#### 5.2 添加具体Library

在需要添加该项目的Module的对应 `build.gradle` 下添加依赖。

```groovy
// <包名>:<项目名>:<版本号>，例如：
compile 'com.gcssloop.demo:uploader:1.0.0'
```
**私有仓库的依赖使用方式和公共仓库远程依赖书写方式相同。**

### 6. 后记

在本系列第一篇文章 [组件化](http://www.gcssloop.com/gebug/componentr) 中，我简单的介绍了将业务模块抽取为组件的优点，这里的私有仓库本质上也是为它服务的。

自己开发一个组件非常简单，但是一定要注意它的源码和文档管理，只有把源码的文档管理做好了，才能方便后续人员接手维护，否则单独抽取一个无法维护的组件是毫无意义的。

有人可能会注意到，我在上传脚本中添加了一个 pack 方法，这个方法用于打包源码，也可以说是创建当前工程的一个快照，我一般在开发完成一个小版本后就会打包一次，它会自动打包成为这样的格式 `项目名_v1.0.0.zip` ，相当于对每一个版本的源码都进行了保存，之后再配合 git 等工具进行源码管理。

**也许有人会有疑问，既然用 git 管理了，何必在自己保存每一个版本的源码呢？**
这主要是因为，git 虽然强大，但毕竟还是要自己手动提交的，有时比较懒，就容易漏掉几个小版本，而使用脚本直接双击就自动保存快照了，相比于git会快捷很多，并且，在需要某个特定版本源码的时候，也无需去git找提交记录了，直接把对应版本的zip文件解压一下就可以了。

最后，私有仓库也并非是必须的，但如果你想自己开发维护一些私有组件库的话，非常推荐一试。

