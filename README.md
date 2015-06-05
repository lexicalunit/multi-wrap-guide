# Multi Wrap Guide

Provides multiple draggable wrap guides.

![preview](https://cloud.githubusercontent.com/assets/1903876/7998617/65c03c2a-0b04-11e5-8417-f3f992d1d818.gif)

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

Then add modifications to the selectors shown below. For example, to make the guide lines purple and the tooltip green:

```less
atom-text-editor::shadow {
  .multi-wrap-guide {

    .multi-wrap-guide-line {
      background-color: purple;

      .multi-wrap-guide-tip {
        background-color: green;
      }
    }
  }
}
```

## Future Work

- Create some spec tests!
- Add continuous integration (blocked by spec tests).
- Create and remove guides without having to edit `config.cson`.
- Source level documentation.
- Refactor duplicated code.
- Better way to capture mouse?
- Refactor `handleEvents` code?
- Allow multi-columns settings per language?
- Styling options for guides in settings?
- Improve any performance issues?
