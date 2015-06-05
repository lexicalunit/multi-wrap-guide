# Multi Wrap Guide

Fully customizable wrap guides at multiple column positions.

**Multiple wrap guides**

![guides](https://cloud.githubusercontent.com/assets/1903876/8000958/76513892-0b26-11e5-80ab-aa630ccf0635.png)

**Draggable wrap guides**

![preview](https://cloud.githubusercontent.com/assets/1903876/7998617/65c03c2a-0b04-11e5-8417-f3f992d1d818.gif)

**Create and remove guides easily**

![before](https://cloud.githubusercontent.com/assets/1903876/8014214/8778f16e-0b94-11e5-921a-4a3126251db6.png)
![context](https://cloud.githubusercontent.com/assets/1903876/8014215/877b79e8-0b94-11e5-8c88-7e1ba4270484.png)
![after](https://cloud.githubusercontent.com/assets/1903876/8014216/877d2dd8-0b94-11e5-8705-9f43ddeba541.png)

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

Or if you want to get really fancy, you can set a different color for each column:

```less
atom-text-editor::shadow {
  .multi-wrap-guide:nth-child(1) .multi-wrap-guide-line {
    background-color: fadeout(white, 70%);
  }
  .multi-wrap-guide:nth-child(2) .multi-wrap-guide-line {
    background-color: fadeout(green, 70%);
  }
  .multi-wrap-guide:nth-child(3) .multi-wrap-guide-line {
    background-color: fadeout(yellow, 70%);
  }
  .multi-wrap-guide:nth-child(4) .multi-wrap-guide-line {
    background-color: fadeout(red, 70%);
  }
}
```

![colors](https://cloud.githubusercontent.com/assets/1903876/8016897/a62f5808-0baf-11e5-9101-0e86638308e7.png)

## Future Work

- Create some spec tests!
- Provide keyboard shortcut to quickly toggle guides on/off.
- Add continuous integration (blocked by creation of spec tests).
- Make guides draggable only at the top, to avoid conflict with selection?
- Better way to capture mouse?
- Allow multi-columns settings per language?
- Styling options for guides in settings?
- Improve any performance issues?

## Notice

Activating this package disables the default Atom `wrap-guide` package automatically.
