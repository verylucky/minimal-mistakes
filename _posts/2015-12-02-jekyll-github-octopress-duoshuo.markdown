---
layout: post
title: Jekyll+Github+Octopress+Duoshuo搭建个人博客
modified:
categories: tech
excerpt: “Jekyll是什么？ Jekyll（发音/’dʒiːk əl/，”杰克尔”）是一个静态站点生成器，它会根据网页源码生成静态文件。它提供了模板、变量、插件等功能，所以实际上可以用来编写整个网站。你先在本地编写符合Jekyll规范的网站源码，然后上传到github，由github生成并托管整个网站。”
tags: ['jekyll', 'Github']
image:
feature:
comments: true
share: false
date: 2015-12-02T19:41:26+08:00
---


###1. Jekyll部署

Jekyll是什么？
Jekyll（发音/'dʒiːk əl/，"杰克尔"）是一个静态站点生成器，它会根据网页源码生成静态文件。它提供了模板、变量、插件等功能，所以实际上可以用来编写整个网站。你先在本地编写符合Jekyll规范的网站源码，然后上传到github，由github生成并托管整个网站。

####安装Ruby####
Jekyll使用ruby开发，第一步必须先安装ruby环境，mac下自带，因此这里pass

####部署Jekyll####
搭建Jekyll环境非常简单，可以参考<http://jekyllrb.com/docs/quickstart/> 但是对于一个后台程序员而言，做界面美化实在是太纠结了，因此果断找开源模板fork之，minimal mistakes是一个相当优秀的模板，链接如下<https://github.com/mmistakes/minimal-mistakes>，然后在基础上进行自定义；
minimal mistakes主题运行在特定的bundle环境下，安装最新的ruby、jekyll可能会出现兼容性问题，如果出现问题，运行
{% highlight bash %}
$ bundle exec jekyll serve
$ bundle exec jekyll build
$ bundle exec octopress new page xxx
$ bundle exec octopress new page xxx
{% endhighlight %}

同时github pages使用git进行同步，几条基本的Git命令还是需要记住
{% highlight bash %}
$ git clone 
$ git status
$ git pull
$ git config 
$ git push origin master
$ git add -A 
$ git commit -m "comment"
{% endhighlight %}

fork下来之后，按照这个配置即可在本地运行主题 <https://mmistakes.github.io/minimal-mistakes/theme-setup/>

####Octopress####
{% highlight ruby %}
def show
  @widget = Widget(params[:id])  
  respond_to do |format|  
    format.html # show.html.erb    
    format.json { render json: @widget }    
  end  
end
{% endhighlight %}

Octopress是一个很强大的博客工具，但是在这里，我们只用它按照模板为我们生成需要发表的文章文件和页面文件模板，只需要如下两个命令：
bundle exec octopress new page xxx
bundle exec octopress new page xxx
默认在_post目录下生成符合jekyll命名要求的文档，在根目录下生成 xxx.html，可以把xxx.html 移动到 xxx文件夹中，然后将文件名改为index.md，简化访问链接

###2. 个性化定制
基本部署完框架，后面就要开始定制化了，一个博客基本的内容至少需要分类categories，标签tags，评论comments，归档archive。Jekyll框架使用Liquid标记语言进行模板处理，整个网站为一个site，每个页面为一个page，每篇文章为一个post。site包括多个categories和tags，每个page也有多个categories和tags，每个tag和category下又有多个post，因此我们需要根据tag和category将文件进行分类，并且按照年限对其归档，同时加上评论功能。
各对象包含的属性参考：<http://jekyllrb.com/docs/variables/> 

**1. 按照tags对文章进行分类 参考 _tags.html**<br>
**2. 按照page的category对文章进行归类 参考 _categories.html**<br>
**3. 按照年份对文章进行归档 参考 _post-index.html**
{:.notice}



###3. 增加评论功能
模板自带disqus评论组件，只需要在_config.yml文件中将  disqus-shortname:设置为注册名，然后在post模板中加上comments = true 即可。但是disqus不符合本土化环境，不能集成qq、wx、weibo这几大社交平台，因此选择本土化的多说评论系统。（Ps. 只要打开稍微看看，就知道基本就是照着disqus抄袭过来的，用起来没有一丁点区别）
在_include文件夹下，有个_scripts.html文件，这里包含了google的分析工具和评论插件的公共部分代码，我们需要把多说官网提供的功能部分代码包含进来。


####新建_duoshuo_comments.html
{% highlight js %}
<!-- 多说公共JS代码 start (一个网页只需插入一次) -->
<script type="text/javascript">
var duoshuoQuery = {short_name:"verylucky"};
	(function() {
		var ds = document.createElement('script');
		ds.type = 'text/javascript';ds.async = true;
		ds.src = (document.location.protocol == 'https:' ? 'https:' : 'http:') + '//static.duoshuo.com/embed.unstable.js';
		ds.charset = 'UTF-8';
		(document.getElementsByTagName('head')[0]
		 || document.getElementsByTagName('body')[0]).appendChild(ds);
	})();
	</script>
<!-- 多说公共JS代码 end -->
{% endhighlight %}

####将下面代码加在_scripts.html底部
{% highlight text %}
{ if page.comments }
  { include _duoshuo_comments.html }
{ endif }
//去掉了百分号，因为blog本身使用liquid解析，会被解析成html代码
{% endhighlight %}


####接口部分代码
{% highlight html %}
    <section class="ds-thread" data-thread-key="{{ date }}" data-title="{{title}}" data-url="{{site.production_url}}{{ page.url }}"></section>
{% endhighlight %}
  
####使用CSS去掉部分不想显示的内容
{% highlight css %}
<style type="text/css">
    .ds-powered-by
    {
        display:none;
    }
    .ds-meta
    {
        display:none;
    }
    .ds-comments-info
    {
        display:none;
    }
    .ds-paginator
    {
        display:none;
    }
    </style>
{% endhighlight %}


###4. 设置Github Pages域名解析
购买域名后，如果是二级域名，则建立CNAME记录，将username.github.io映射到自己的域名；如果是一级域名，则建立A记录，将域名映射到上面链接给出的两个ip地址之一，通过该域名访问到该ip之后，Github会根据根目录下CNAME文件标记的域名进行解析，找到对应的pages页面。
参考下面链接:<br>
<https://help.github.com/articles/setting-up-a-custom-domain-with-github-pages/><br>
至此，等域名解析生效，即可访问你的个人博客了。
