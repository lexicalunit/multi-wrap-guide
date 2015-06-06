# Multi Wrap Guide

Fully customizable wrap guides at multiple column positions.

**Multiple wrap guides**

![guides](https://cloud.githubusercontent.com/assets/1903876/8000958/76513892-0b26-11e5-80ab-aa630ccf0635.png)

**Draggable wrap guides**

![preview](https://cloud.githubusercontent.com/assets/1903876/7998617/65c03c2a-0b04-11e5-8417-f3f992d1d818.gif)

> Easily disable draggable guides by using the `Multi Wrap Guide: Lock Guides` command. This is especially useful when draggable guides are interfering with text selection.

**Create and remove guides easily**

![before](https://cloud.githubusercontent.com/assets/1903876/8016975/f1a2fab4-0bb0-11e5-9933-365cfe59ea26.png)
![context](https://cloud.githubusercontent.com/assets/1903876/8016976/f1a58c20-0bb0-11e5-8f58-5cdfdcebfd50.png)
![after](https://cloud.githubusercontent.com/assets/1903876/8016977/f1a75c6c-0bb0-11e5-9675-7f15bc80038d.png)

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
- Add continuous integration (blocked by creation of spec tests).
- Make guides draggable only at the top, to avoid conflict with selection?
- Better way to capture mouse?
- Styling options for guides in settings?
- Improve any performance issues?

## Notice

Activating this package disables the default Atom `wrap-guide` package automatically.
