---
layout: post
title: Epoll+Coro的微型服务器框架
modified:
categories: tech
excerpt: Epoll进行收发数据包功能，Coro将异步代码同步化，提高编程效率；
tags: [Linux]
image:
feature:
comments: true
share: false
date: 2016-04-01T12:09:42+08:00
---


### Epoll框架

Epoll是Linux下IO多路复用的增强版本，作为select和poll的升级版，Epoll采用回调机制，大幅度提高了并发效率。select和poll均采用对fd进行轮询的方式，遍历所有连接的fd，找到可读的fd进行读写操作，这种方式在套接字大部分均为活跃的情况下效率是比较高的，但是在现网情况下，数十万的连接中可能只有很小部分是可读的，这样当服务器并发数过高的时候，效率会线性下降。而Epoll通过内核监听注册到epoll上的套接字，通过event机制返回所有的可读写的套接字，然后通过回调方式进行处理，避免了大量套接字的时候轮询开销，可以支持大量FD并发读写，尤其在大量不活跃的链接情况下，其效率明显要高于select和poll。

此外，select，poll方式可以监听的fd是有限的，内核定义了__FD_SETSIZE宏用于限制fd句柄的数量，系统一般默认为1024个，而epoll可以只跟内存大小相关，一般1G内存可以支持10w左右的链接。

### Epoll实现原理

Epoll通过mmap将用户的一块地址空间和内核的一块地址空间映射到同一块物理内存，减少用户态和内核态直接的信息传递，同时内核也可以看到用户态所监听的fd，效率高。用户将fd和event的映射注册到内核维护的一棵红黑树上，当检测到fd上有数据流，则将该映射复制到一个双向链表上，然后通过epoll_wait返回所有的注册的event。如果该链表为空，则阻塞在epoll_wait，挂起当前进程。

### Epoll的两种工作模式 LT&ET
LT，水平触发模式，简单理解就是只要fd中有可读数据，系统就会不断重复通知，直到全部读完为止；
ET，边缘触发模式，每次fd有变动的时候，便会收到一个内核通知，但是读完一次之后，即使没读完，系统也不会再进行通知，ET是一种更高效的并发模式；
附上链接，这两篇博客详细说明了Epoll和LT&ET模式

* <http://www.cnblogs.com/lojunren/p/3856290.html>
* <http://blog.chinaunix.net/uid/28541347/sid-193117-list-1.html>

### Epoll编程接口

和传统Socket编程一样，绑定ip和端口，并且开启监听，唯一区别在于不在accept阻塞，等listenfd变为可读，而是将listenfd注册到epfd，然后在epoll_wait处hang住，等系统回调；下面列举了两个主要的函数，```sock_bind```用于绑定ip和端口，注册listenfd；
{% highlight c %}

int EpollServer::sock_bind(const char* ip, const int port)
{
    struct sockaddr_in local;
    memset(&local, 0, sizeof(local));

    if( (listenfd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    {
        perror("sockfd\n");
        exit(1);
    }
    setnonblocking(listenfd);
    local.sin_family = AF_INET;
    local.sin_addr.s_addr = inet_addr(ip);
    local.sin_port= htons(port);
    if(bind(listenfd, (struct sockaddr*)&local, sizeof(local)) < 0)
    {
        perror("bind\n");
        exit(1);
    }
    listen(listenfd, MAX_CLIENT);
    epollfd = epoll_create(20);
    
    if(epollfd == -1)
    {
        perror("epoll_create\n");
        exit(EXIT_FAILURE);
    }

    //不需要多个ev，因为都是拷贝到epoll内核的，每次wait到之后再拷贝回来，可以复用一个ev即可
    struct epoll_event ev;
    ev.events = EPOLLIN | EPOLLET;
    ev.data.fd = listenfd;
    if(epoll_ctl(epollfd, EPOLL_CTL_ADD, listenfd, &ev) == -1)
    {
        perror("epoll_ctl\n");
        exit(EXIT_FAILURE);
    }
    return 0;
}

{% endhighlight %}


```handle_connection```用于在epoll_wait等待链接，如果所有fd均为不可读，没有事件通知，则hang住进程，否则返回所有的可读fd，存于ev数组中，ret是fd的数量，然后对每个根据ev上的fd和注册的事件信息进行回调处理；其中的协程主要用于响应函数的调度，可以避免异步代码以及上下文切换，异步代码同步化，可以提高代码可读性，提高编程效率。
{% highlight c %}

int EpollServer::handle_connection()
{
    struct epoll_event ev[1024];
    char buf[1024];
    memset(buf, 0, sizeof(buf));
    while(1)
    {
        int ret = epoll_wait(epollfd, ev, 1024, -1);
        for(int i = 0; i < ret; i++)
        {
            if(ev[i].data.fd == listenfd && (ev[i].events & EPOLLIN))
            {             
                struct sockaddr_in client_addr;
                memset(&client_addr, 0, sizeof(client_addr));
                socklen_t addr_len = sizeof(client_addr);
                int clientfd = accept(listenfd, (struct sockaddr*)&client_addr, &addr_len);
                if(clientfd == -1)
                {
                    printf("accept error!\n");
                    return -1;
                }
                else 
                {
                    printf("accept a new client: %s:%d\n",inet_ntoa(client_addr.sin_addr),client_addr.sin_port);
                }

                ev[i].data.fd = clientfd;
                ev[i].events = EPOLLIN|EPOLLET|EPOLLERR|EPOLLRDHUP;
                epoll_ctl(epollfd, EPOLL_CTL_ADD, ev[i].data.fd, &ev[i]);
                //为该链接创建一个session 保存链接信息 创建协程 加入map
                //创建协程
                Coro *hcoro =(Coro*) malloc(sizeof(Coro));
                hcoro->init(clientfd, CORO_STACK_SIZE);
                CoroMgr::getInstance().add_coro(clientfd, hcoro);
                
            }
            else if(ev[i].events & EPOLLIN)
            {
                printf("in EPOLLIN\n");
                
                int ret = recv(ev[i].data.fd, buf, sizeof(buf), 0);
                if(ret == 0)
                {
                    printf("client closed...\n");
                    epoll_ctl(epollfd, EPOLL_CTL_DEL, ev[i].data.fd, &ev[i]);
                    break;
                }
                else
                {
                    printf("message recv: %s", buf);
                    //send(ev[i].data.fd, buf, sizeof(buf), 0);
                    ev[i].events = EPOLLIN | EPOLLET ;
                    epoll_ctl(epollfd, EPOLL_CTL_MOD, ev[i].data.fd, &ev[i]);
                }
                
                //resume协程，传入函数和数据，进行处理
                Coro *hcoro = CoroMgr::getInstance().get_coro(ev[i].data.fd);
                if(!hcoro)
                {
                    printf("hcoro null \n");
                    return -1;
                }

                //以后改成解析数据包，根据cmd寻找响应函数
                int cmd = atoi(buf);
                if(cmd != 1 && cmd != 2)
                {
                    printf("cmd error\n");
                    continue;
                }
                hcoro->setCmd(cmd);
                hcoro->resume();
                printf("back resume\n");
            }   
            else if(ev[i].events & EPOLLOUT)
            {
                printf("In EPOLLOUT\n");
                send(ev[i].data.fd, buf, sizeof(buf), 0);
                
                ev[i].events = EPOLLIN | EPOLLET ;
                epoll_ctl(epollfd, EPOLL_CTL_ADD, ev[i].data.fd, &ev[i]);
            }
        }
    }
    return 0;
}

int main()
{    
    //初始化协程调度器
    CoroMgr &mgr = CoroMgr::getInstance();
    mgr.init();
    
    EpollServer srv;
    srv.sock_bind("127.0.0.1", 8888);
    srv.handle_connection();
    return 0;
}

{% endhighlight %}

### 协程


#### 优点

* 代码编辑简单。可以将异步处理逻辑代码用同步的方式编写，将多个异步操作集中到一个函数中完成，不需要维护过多的session数据或状态机，同时兼备异步的高效。
* 如果一个业务逻辑中涉及到多个异步请求，使用传统的异步回调方式，会使代码变得很凌乱，逻辑被不同的函数分享的支离破碎，非常不便于代码阅读。如果使用协程，可以将一个完整的业务逻辑集中在一个函数中完成，一眼了然。
* 编程简单。单线程模式，没有线程安全的问题，不需要加锁操作。
* 性能好。协程是用户态线程，切换更加高效。

#### 缺点
* 在协程执行中不能有阻塞操作，否则整个线程被阻塞
* 有注意全局变量、指针的使用


#### 使用方式

携程核心用法就是resume和yield函数，在linux系统中一般使用swapcontext实现，函数原型是```int swap_context(ucontext* uctx, ucontext* new_uctx)```, 保存当前上下文到uctx，切换到new_uctx代表的上下文环境中。在服务器交互中一般如下图所示。

<img src="{{site.url}}/images/coro.png" width = "600" alt="coro" />

协程详细说明：<http://gcloud.qq.com/forum/topic/569c4d895c4720d06f31c91b>

源码地址链接：<https://github.com/verylucky/microserver>
