# Multi Wrap Guide

Provides multiple wrap guides at the columns you specify.

![guides](https://cloud.githubusercontent.com/assets/1903876/7960481/84dfd8b6-09c6-11e5-94a3-a4f946a9d6f2.png)

## Configuration

Uses `editor.preferredLineLength` or [language specific setting](http://blog.atom.io/2014/10/31/language-scoped-config.html) if one is available. You can override these defaults by providing something like the following in your `config.cson` file:

```coffeescript
  'multi-wrap-guide':
    'columns': [
      73
      80
      100
      120
    ]
```

## Future Work

- Allow multiple columns settings per language.
- Create and remove guides without having to edit `config.cson`.
- Styling options for guides.
- Source level documentation.
- Disable `wrap-guide` package automatically.
