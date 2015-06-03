# Multi Wrap Guide

Provides multiple wrap guides at the columns you specify.

![guides](https://cloud.githubusercontent.com/assets/1903876/7960481/84dfd8b6-09c6-11e5-94a3-a4f946a9d6f2.png)

## Configuration

By default, Multi Wrap Guide will use your `editor.preferredLineLength` setting or [language specific settings](http://blog.atom.io/2014/10/31/language-scoped-config.html). You can override this by editing your `config.cson` file to provide custom settings. First open the file using the following command.

```
Command Palette ➔ Application: Open Your Config
```

Then add something like the following under the root `'*'` scope.

```coffeescript
  'multi-wrap-guide':
    'columns': [
      73
      80
      100
      120
    ]
```

## Styling

You can modify the styles applied to guides created by this package using your `styles.less` file. Open it with the following command.

```
Command Palette ➔ Application: Open Your Stylesheet
```

Then add modifications to the `atom-text-editor::shadow .multi-wrap-guide` selector. For example, to make the guide lines purple you could add something like the following.

```css
atom-text-editor::shadow {
  .multi-wrap-guide {
    background-color: pruple;
  }
}
```

## Future Work

- Create some spec tests!
- Source level documentation.
- Create and remove guides without having to edit `config.cson`.
- Allow multiple columns settings per language?
- Disable `wrap-guide` package automatically?
- Styling options for guides in settings?
