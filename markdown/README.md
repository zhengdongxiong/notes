<!--
注释
-->
# 目录
- [目录名称](#跳转到标题名)
	- [二级目录](#跳转到标题名)
	- [带标号表格](#1-表格)

# 一级标题

### 三级标题

# 字体效果
_斜体_
*斜体*
**加粗**
__加粗__
***加粗斜体***
___加粗斜体___
~~删除线~~

# 脚注
格式
这是一个脚注[^描述]
[^描述]: 这是一个脚注

# 空格缩进
&nbsp; 空格

# 分割线
---
***
# 图片
![图片下面文字](图片地址 "图片标题")

# 超链接
[超链接名](超链接地址 "超链接标题")

# 变量设置超链接
[文档显示名][放置在文档末尾]
[放置在文档末尾]: 链接


# 链接嵌套图片
[![]()]()

# 页内跳转
设置标记点
<span id="目录1"></span>
引用方式
[描述](#目录1)

# 1 表格
| 表头 | 表头 | 表头 | 表头 |
| :--- | ---: | :---: | --- |
| 左对齐 | 右对齐 | 居中 | 默认 |
| 左对齐 | 右对齐 | 居中 | 默认 |

# 有序列表
1. 列表一
	1.1 列表一点一
2. 列表二
	2.1 列表二点一

# 无序列表
* 无序列表一
+ 无序列表二
- 无序列表三

# 横向/竖向流程图
## 格式
```mermaid
```
graph LR 横向
graph TD 纵向
## 元素定义
id[描述] 直角矩形
id(描述) 圆角
id{描述} 菱形
id>描述] 不对称矩形
id((描述)) 圆形
## 线条定义
A --> B 带箭头
A --- B 不带箭头
A -.- B 虚线连接
A -.-> B 虚线指向
A ==> B 加粗箭头指向
A --- |描述| B 不带箭头指向在线段中添加描述
A ----> |描述| B 带描述的箭头指向
A -..-> |描述| B 带描述的虚线连指向
A ====> |描述| B 带描述的加粗箭头指向
## 子流程图定义
subgraph title
	graph direction
end
graph TB
	c1-->a2
	subgraph 第一组
	a1-->a2
	end
	subgraph 第二组
	c1-->c2
	end

# 标准流程图
## 格式
```flow
```
## 模块定义
id=>关键字: 描述
id=>关键字: 描述:>url 与描述文本绑定的链接
关键字
start 流程开始, 圆角矩形
operation 操作, 直角矩形
condition 判断, 菱形
subroutine 子流程, 左右带空白框矩形
inputoutput 输入输出, 平行四边形
end 结束, 圆角矩形

模块1 id->模块2 id
条件模块id (描述)->模块id(direction) 条件模块跳转到对应的执行模块, 指定对应分支的布局方向
子流程id (right/left)->模块id 子流程右/左空白框指向
