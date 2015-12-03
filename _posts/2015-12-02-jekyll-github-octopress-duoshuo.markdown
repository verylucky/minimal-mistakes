---
layout: post
title: Jekyll+Github+Octopress+Duoshuo搭建个人博客
modified:
categories: tech
excerpt:
tags: ['jekyll', 'Github']
image:
feature:
comments: true
share: false
date: 2015-12-02T19:41:26+08:00
---


## Jekyll部署

Jekyll是什么？
Jekyll（发音/'dʒiːk əl/，"杰克尔"）是一个静态站点生成器，它会根据网页源码生成静态文件。它提供了模板、变量、插件等功能，所以实际上可以用来编写整个网站。你先在本地编写符合Jekyll规范的网站源码，然后上传到github，由github生成并托管整个网站。

**安装Ruby**

Jekyll使用ruby开发，第一步必须先安装ruby环境，mac下自带，因此这里pass

**部署Jekyll**

搭建Jekyll环境非常简单，可以参考<http://jekyllrb.com/docs/quickstart/> 但是对于一个后台程序员而言，做界面美化实在是太纠结了，因此果断找开源模板fork之，minimal mistakes是一个相当优秀的模板，链接如下<https://github.com/mmistakes/minimal-mistakes>，然后在基础上进行自定义；

minimal mistakes主题运行在特定的bundle环境下，安装最新的ruby、jekyll可能会出现兼容性问题，如果出现问题，运行bundle exec jekyll serve
bundle exec jekyll build
bundle exec octopress new page xxx
bundle exec octopress new page xxx

同时github pages使用git进行同步，几条基本的Git命令还是需要记住
git clone
git status
git pull
git config
git push origin master
git add -A
git commit -m "comment"

fork下来之后，按照这个配置即可在本地运行主题 <https://mmistakes.github.io/minimal-mistakes/theme-setup/>

**Octopress**

Octopress是一个很强大的博客工具，但是在这里，我们只用它按照模板为我们生成需要发表的文章文件和页面文件模板，只需要如下两个命令：
bundle exec octopress new page xxx
bundle exec octopress new page xxx
默认在_post目录下生成符合jekyll命名要求的文档，在根目录下生成 xxx.html，可以把xxx.html 移动到 xxx文件夹中，然后将文件名改为index.md，简化访问链接

##个性化定制
基本部署完框架，后面就要开始定制化了，一个博客基本的内容至少需要分类categories，标签tags，评论comments，归档archive。Jekyll框架使用Liquid标记语言进行模板处理，整个网站为一个site，每个页面为一个page，每篇文章为一个post。site包括多个categories和tags，每个page也有多个categories和tags，每个tag和category下又有多个post，因此我们需要根据tag和category将文件进行分类，并且按照年限对其归档，同时加上评论功能。
各对象包含的属性参考：<>

***按照tags对文章进行分类***
{% for tag in site.tags %}
      <h3>{{ tag[0] }}</h3>
      {% for post in site.posts %}
        {% for post_tag in post.tags %}
          {% if post_tag == tag[0] %}
            <article>
            {% capture date %}{{ post.date | date: "%b %d, %y" }}{% endcapture %}
            {% if post.link %}
              <h4 class="link-post"><a href="{{ site.url }}{{ post.url }}" title="{{ post.title }}">{{ post.title }}</a> <a href="{{ post.link }}" target="_blank" title="{{ post.title }}"><i class="fa fa-link"></i></a></h4>
            {% else %}
              <span><a href="{{ site.url }}{{ post.url }}" title="{{ post.title }}" style="color:blue">{{ post.title }}</a></span>
              {% if post.excerpt %}
                <p>{{ post.excerpt | strip_html | truncate: 160 }}</p>
              {% endif %}
            </article>
            {% endif %}
          {% endif %}
        {% endfor %}
      {% endfor %}
    {% endfor %}


***按照page的category对文章进行归类***
{% for page_category in page.categories %}
      {% assign cat = page_category %}
      {% for post in site.categories.[cat] %}
        <article>
          {% capture date %}{{ post.date | date: "%b %d, %y" }}{% endcapture %}
          {% if post.link %}
            <h2 class="link-post"><a href="{{ site.url }}{{ post.url }}" title="{{ post.title }}">{{ post.title }}</a> <a href="{{ post.link }}" target="_blank" title="{{ post.title }}"><i class="fa fa-link"></i></a></h2>
          {% else %}
            <h2><a href="{{ site.url }}{{ post.url }}" title="{{ post.title }}">{{ post.title }}</a></h2>
            <p>{{ post.excerpt | strip_html | truncate: 160 }}</p>
            <!--strong>Published on {{ date }}</strong-->
          {% endif %}
        </article>
        <hr>
      {% endfor %}
    {% endfor %}

***按照年份对文章进行归档***
<h1>{{ page.title }}</h1>
    {% capture written_year %}'None'{% endcapture %}
    {% for post in site.posts %}
      {% capture year %}{{ post.date | date: '%Y' }}{% endcapture %}
      {% capture written_time %}{{ post.date | date: '%B %d ,%y' }}{% endcapture %}
      {% if year != written_year %}
        <h3>{{ year }}</h3>
        {% capture written_year %}{{ year }}{% endcapture %}
      {% endif %}
      <article>
        {% if post.link %}
          <h2 class="link-post"><a href="{{ site.url }}{{ post.url }}" title="{{ post.title }}">{{ post.title }}</a> <a href="{{ post.link }}" target="_blank" title="{{ post.title }}"><i class="fa fa-link"></i></a></h2>
        {% else %}
          {{ written_time }}&nbsp;&nbsp;<span><a href="{{ site.url }}{{ post.url }}" title="{{ post.title }}" style="color:blue" >{{ post.title }} </a></span>
          <!--p>{{ post.excerpt | strip_html | truncate: 160 }}</p-->
        {% endif %}
      </article>
    {% endfor %}


##增加评论功能
模板自带disqus评论组件，只需要在_config.yml文件中将  disqus-shortname:设置为注册名，然后在post模板中加上comments = true 即可。但是disqus不符合本土化环境，不能集成qq、wx、weibo这几大社交平台，因此选择本土化的多说评论系统。（Ps. 只要打开稍微看看，就知道基本就是照着disqus抄袭过来的，用起来没有一丁点区别）
在_include文件夹下，有个_scripts.html文件，这里包含了google的分析工具和评论插件的公共部分代码，我们需要把多说官网提供的功能部分代码包含进来。

***新建_duoshuo_comments.html***
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

***将下面代码加在_scripts.html底部***
{% if page.comments %}
  {% include _duoshuo_comments.html %}
{% endif %}

***接口部分代码***
{% if site.owner.duoshuo-shortname and page.comments == true %}
    <section class="ds-thread" data-thread-key="{{ date }}" data-title="{{title}}" data-url="{{site.production_url}}{{ page.url }}"></section>
  {% endif %}

***使用CSS去掉部分不想显示的内容***
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

##设置Github Pages域名解析

购买域名后，如果是二级域名，则建立CNAME记录，将username.github.io映射到自己的域名；如果是一级域名，则建立A记录，将域名映射到上面链接给出的两个ip地址之一，通过该域名访问到该ip之后，Github会根据根目录下CNAME文件标记的域名进行解析，找到对应的pages页面。
参考下面链接：
<https://help.github.com/articles/setting-up-a-custom-domain-with-github-pages/>

### Syntax

#### Strong and Emphasize

**strong** or __strong__ ( Cmd + B )

*emphasize* or _emphasize_ ( Cmd + I )

**Sometimes I want a lot of text to be bold.
Like, seriously, a _LOT_ of text**

#### Blockquotes

> Right angle brackets &gt; are used for block quotes.

#### Links and Email

An email <example@example.com> link.

Simple inline link <http://chenluois.com>, another inline link [Smaller](http://25.io/smaller/), one more inline link with title [Resize](http://resizesafari.com "a Safari extension").

A [reference style][id] link. Input id, then anywhere in the doc, define the link with corresponding id:

[id]: http://25.io/mou/ "Markdown editor on Mac OS X"

Titles ( or called tool tips ) in the links are optional.

#### Images

An inline image ![Smaller icon](http://25.io/smaller/favicon.ico "Title here"), title is optional.

A ![Resize icon][2] reference style image.

[2]: http://resizesafari.com/favicon.ico "Title"

#### Inline code and Block code

Inline code are surround by `backtick` key. To create a block code:

	Indent each line by at least 1 tab, or 4 spaces.
    var Mou = exactlyTheAppIwant;

####  Ordered Lists

Ordered lists are created using "1." + Space:

1. Ordered list item
2. Ordered list item
3. Ordered list item

#### Unordered Lists

Unordered list are created using "*" + Space:

* Unordered list item
* Unordered list item
* Unordered list item

Or using "-" + Space:

- Unordered list item
- Unordered list item
- Unordered list item

#### Hard Linebreak

End a line with two or more spaces will create a hard linebreak, called `<br />` in HTML. ( Control + Return )  
Above line ended with 2 spaces.

#### Horizontal Rules

Three or more asterisks or dashes:

***

---

- - - -

#### Headers

Setext-style:

This is H1
==========

This is H2
----------

atx-style:

# This is H1
## This is H2
### This is H3
#### This is H4
##### This is H5
###### This is H6




### Extra Syntax

#### Footnotes

Footnotes work mostly like reference-style links. A footnote is made of two things: a marker in the text that will become a superscript number; a footnote definition that will be placed in a list of footnotes at the end of the document. A footnote looks like this:

That's some text with a footnote.[^1]

[^1]: And that's the footnote.


#### Strikethrough

Wrap with 2 tilde characters:

~~Strikethrough~~


#### Fenced Code Blocks

Start with a line containing 3 or more backticks, and ends with the first line with the same number of backticks:

```
Fenced code blocks are like Stardard Markdown’s regular code
blocks, except that they’re not indented and instead rely on
a start and end fence lines to delimit the code block.
```

#### Tables

A simple table looks like this:

First Header | Second Header| Third Header
------------ | ------------ | ------------
Content Cell | Content Cell | Content Cell
Content Cell | Content Cell | Content Cell

If you wish, you can add a leading and tailing pipe to each line of the table:

| First Header | Second Header | Third Header |
| ------------ | ------------- | ------------ |
| Content Cell | Content Cell  | Content Cell |
| Content Cell | Content Cell  | Content Cell |

Specify alignment for each column by adding colons to separator lines:

First Header | Second Header | Third Header
:----------- | :-----------: | -----------:
Left         | Center        | Right
Left         | Center        | Right


### Shortcuts

#### View

* Toggle live preview: Shift + Cmd + I
* Toggle Words Counter: Shift + Cmd + W
* Toggle Transparent: Shift + Cmd + T
* Toggle Floating: Shift + Cmd + F
* Left/Right = 1/1: Cmd + 0
* Left/Right = 3/1: Cmd + +
* Left/Right = 1/3: Cmd + -
* Toggle Writing orientation: Cmd + L
* Toggle fullscreen: Control + Cmd + F

#### Actions

* Copy HTML: Option + Cmd + C
* Strong: Select text, Cmd + B
* Emphasize: Select text, Cmd + I
* Inline Code: Select text, Cmd + K
* Strikethrough: Select text, Cmd + U
* Link: Select text, Control + Shift + L
* Image: Select text, Control + Shift + I
* Select Word: Control + Option + W
* Select Line: Shift + Cmd + L
* Select All: Cmd + A
* Deselect All: Cmd + D
* Convert to Uppercase: Select text, Control + U
* Convert to Lowercase: Select text, Control + Shift + U
* Convert to Titlecase: Select text, Control + Option + U
* Convert to List: Select lines, Control + L
* Convert to Blockquote: Select lines, Control + Q
* Convert to H1: Cmd + 1
* Convert to H2: Cmd + 2
* Convert to H3: Cmd + 3
* Convert to H4: Cmd + 4
* Convert to H5: Cmd + 5
* Convert to H6: Cmd + 6
* Convert Spaces to Tabs: Control + [
* Convert Tabs to Spaces: Control + ]
* Insert Current Date: Control + Shift + 1
* Insert Current Time: Control + Shift + 2
* Insert entity <: Control + Shift + ,
* Insert entity >: Control + Shift + .
* Insert entity &: Control + Shift + 7
* Insert entity Space: Control + Shift + Space
* Insert Scriptogr.am Header: Control + Shift + G
* Shift Line Left: Select lines, Cmd + [
* Shift Line Right: Select lines, Cmd + ]
* New Line: Cmd + Return
* Comment: Cmd + /
* Hard Linebreak: Control + Return

#### Edit

* Auto complete current word: Esc
* Find: Cmd + F
* Close find bar: Esc

#### Post

* Post on Scriptogr.am: Control + Shift + S
* Post on Tumblr: Control + Shift + T

#### Export

* Export HTML: Option + Cmd + E
* Export PDF:  Option + Cmd + P


### And more?

Don't forget to check Preferences, lots of useful options are there.

Follow [@Mou](https://twitter.com/mou) on Twitter for the latest news.

For feedback, use the menu `Help` - `Send Feedback`
