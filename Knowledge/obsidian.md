# 1. pdf导出

安装minimal主题之后，代码段为黑色，并且表格非常难看，之后找到了这篇文章：

[PDF and print style reset with code syntax highlighting - Share & showcase - Obsidian Forum](https://forum.obsidian.md/t/pdf-and-print-style-reset-with-code-syntax-highlighting/31761)

因此新建如下代码片段放到`.obsidian/snippets`目录下，并在obsidian中应用即可：

```css
@media print {
  h1, h2, h3, h4, h5, h6, p, ul, li, ol {
    font-size: initial;
    font-weight: initial;
    font-family: initial;
    color: initial !important;
    background: none !important;
    outline: none !important;
    border: none !important;
    text-shadow: none !important;
  }

  th, td {
    font-size: initial;
    font-weight: initial;
    font-family: initial;
    color: initial !important;
    background: none !important;
    outline: none !important;
    text-shadow: none !important;
    border: 1px solid darkgray !important;
  }

  a {
    font-size: initial;
    font-weight: initial;
    font-family: initial;
    color: blue !important;
    text-decoration: underline !important;
    background: none !important;
    outline: none !important;
    border: none !important;
    text-shadow: none !important;
  }

  a[aria-label]::after {
    display: inline !important;
    content: " (" attr(aria-label) ")" !important;
    color: #666 !important;
    vertical-align: super !important;
    font-size: 70% !important;
    text-decoration: none !important;
  }

  pre,
  code span,
  code {
    color: black !important;
    background-color: white !important;
  }

  code {
    border: 1px solid darkgray !important;
    padding: 0 0.2em !important;
    line-height: initial !important;
    border-radius: 0 !important;
  }

  pre {
    border: 1px solid darkgray !important;
    margin: 1em 0px !important;
    padding: 0.5em !important;
    border-radius: 0 !important;
  }

  pre > code {
    font-size: 12px !important;
    border: none !important;
    border-radius: 0 !important;
    padding: 0 !important;
  }

  pre > code .token.em { font-style: italic !important; }
  pre > code .token.link { text-decoration: underline !important; }
  pre > code .token.strikethrough { text-decoration: line-through !important; }
  pre > code .token { color: #000 !important; }
  pre > code .token.keyword { color: #708 !important; }
  pre > code .token.number { color: #164 !important; }
  pre > code .token.variable {  }
  pre > code .token.punctuation {  }
  pre > code .token.property {  }
  pre > code .token.operator {  }
  pre > code .token.def { color: #00f !important; }
  pre > code .token.atom { color: #219 !important; }
  pre > code .token.variable-2 { color: #05a !important; }
  pre > code .token.type { color: #085 !important; }
  pre > code .token.comment { color: #a50 !important; }
  pre > code .token.string { color: #a11 !important; }
  pre > code .token.string-2 { color: #f50 !important; }
  pre > code .token.meta { color: #555 !important; }
  pre > code .token.qualifier { color: #555 !important; }
  pre > code .token.builtin { color: #30a !important; }
  pre > code .token.bracket { color: #997 !important; }
  pre > code .token.tag { color: #170 !important; }
  pre > code .token.attribute { color: #00c !important; }
  pre > code .token.hr { color: #999 !important; }
  pre > code .token.link { color: #00c !important; }
}
```



#TODO 
- [ ] 学习Dataview插件的使用