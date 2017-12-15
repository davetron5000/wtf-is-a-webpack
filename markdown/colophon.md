This book is written in a modified version of [Markdown](https://daringfireball.net/projects/markdown/syntax), processed by [Redcarpet](https://github.com/vmg/redcarpet) using a system I created called [Bookdown](https://github.com/davetron5000/bookdown). It allows me to write text and code together, such that when the Markdown source is processed, the code examples execute.  It's sort of like a reverse of [literate programming](https://en.wikipedia.org/wiki/Literate_programming).  The source content is [hosted on GitHub](https://github.com/davetron5000/wtf-is-a-webpack).

The headers are set in Avenir Next, defaulting to the system sans-serif if Avenir is not available.  The body text is set in
Baskerville, falling back to Georgia, then Times, then the system serif font.

Code is set in Courier with syntax highlighting provided by [highlight.js](https://highlightjs.org).

Interestingly, I didn't use Webpack or Tachyons for any of this.  Tachyons isn't suited well if you don't control the markup, because you don't have access to the entities to add `class` attributes.  Webpack felt like overkill for the small amount of JavaScript needed to make the table of contents work.

Thanks for reading!

<aside class="signoff">
Dave <code>davec@naildrivin5.com</code>
</aside>
