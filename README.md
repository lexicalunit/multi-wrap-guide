# Multi Wrap Guide

[![Build Status](https://travis-ci.org/lexicalunit/multi-wrap-guide.svg?branch=master)](https://travis-ci.org/lexicalunit/multi-wrap-guide) [![Dependency Status](https://david-dm.org/lexicalunit/multi-wrap-guide.svg)](https://david-dm.org/lexicalunit/multi-wrap-guide)

Fully customizable wrap guides at arbitrary column positions.

**Wrap guides!**

![guides](https://cloud.githubusercontent.com/assets/1903876/8047184/b1fc4a9c-0e07-11e5-943f-ebffd647c2e0.png)

**Drag 'em!**

![drag](https://cloud.githubusercontent.com/assets/1903876/8047183/b1f95c24-0e07-11e5-9c53-d2e1ba4cd273.gif)

> Disable draggable guides by using the `Multi Wrap Guide: Toggle Lock` command. This is useful when draggable guides are interfering with text selection.

**Create and remove 'em!**

![create](https://cloud.githubusercontent.com/assets/1903876/8047182/b1f6e340-0e07-11e5-8db5-99add2af6646.gif)

## Uninstallation

<div style="background-color: #fcf2f2; border-color: #dFb5b4; border-left: 5px solid #dfb5b4; padding: 0.5em;">Activating this package **disables** the default Atom `wrap-guide` package automatically. To go back to using the default wrap guide you'll need to deactivate or uninstall `multi-wrap-guide` *and then manually re-enable the `wrap-guide` package* in your Atom settings.</div>

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

> Note that the final column given will act as your `editor.preferredLineLength` setting. This affects things such as soft word wrap if you also have `editor.softWrapAtPreferredLineLength` enabled.

## Styling

Configure styles applied to guides created by this package using your `styles.less` file. Open it with the following command.

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

Or if you want to get super fancy, you can set different colors and widths for each column:

```less
atom-text-editor::shadow {
  .multi-wrap-guide:nth-child(1) .multi-wrap-guide-line {
    background-color: fadeout(white, 60%);
    width: 1px;
  }
  .multi-wrap-guide:nth-child(2) .multi-wrap-guide-line {
    background-color: fadeout(green, 60%);
    width: 2px;
  }
  .multi-wrap-guide:nth-child(3) .multi-wrap-guide-line {
    background-color: fadeout(yellow, 60%);
    width: 5px;
  }
  .multi-wrap-guide:nth-child(4) .multi-wrap-guide-line {
    background-color: fadeout(red, 60%);
    width: 10px;
  }
}
```

![colors](https://cloud.githubusercontent.com/assets/1903876/8047181/b1ef283a-0e07-11e5-92b9-5c9afbebf29c.png)

## Future Work

- More spec test coverage.
- Up-to-date screenshots.
