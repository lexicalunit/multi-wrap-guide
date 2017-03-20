# Multi Wrap Guide

[![apm package][apm-ver-link]][releases]
[![travis-ci][travis-ci-badge]][travis-ci]
[![appveyor][appveyor-badge]][appveyor]
[![circle-ci][circle-ci-badge]][circle-ci]
[![david][david-badge]][david]
[![download][dl-badge]][apm-pkg-link]
[![mit][mit-badge]][mit]

Fully customizable wrap guides at arbitrary column positions.

**Wrap guides!**

![guides][img-guides]

**Drag 'em!**

![drag][img-drag]

> Disable draggable guides by using the `Multi Wrap Guide: Toggle Lock` command. This is useful when
> draggable guides are interfering with text selection.

**Create and remove 'em!**

![create][img-create]

## Integration with Line Length Break

The [`line-length-break`][line-length-break] package allows users to automatically hard break text
at their editor's preferred line length. If you have this plugin installed, `multi-wrap-guide` will
add a context sensitive menu item (right click on a wrap guide) that will let you line break at the
selected wrap guide. Using the `Line Length Break: Break` will break at the farthest right wrap
guide by default.

## Configuration

By default, Multi Wrap Guide will use your `editor.preferredLineLength` setting or
[language specific settings][language-specific-settings]. You can override this by editing your
`config.cson` file to provide custom settings. First open the file using the following command.

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

> :warning: Note that the final column given will act as your `editor.preferredLineLength` setting.
> This affects preferences such as soft word wrap if you also have
> `editor.softWrapAtPreferredLineLength` enabled.

## Styling

Configure styles applied to guides created by this package using your `styles.less` file. Open it
with the following command.

```
Command Palette ➔ Application: Open Your Stylesheet
```

Then add modifications to the selectors shown below. For example, to make the guide lines purple
and the tooltip green:

```less
atom-text-editor.editor {
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
atom-text-editor.editor {
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

![colors][img-colors]

## Uninstallation

Activating this package **disables** the default Atom
`wrap-guide` package automatically. To go back to using the default wrap guide you'll
need to deactivate or uninstall `multi-wrap-guide` _and then manually re-enable the
`wrap-guide` package_ in your Atom settings.

Also, if you have changed your right-most vertical wrap guide since installing
`multi-wrap-guide`, your `editor.preferredLineLength` will be different than
from before you installed `multi-wrap-guide`. This is not a permanent change as you are
of course free to change your `editor.preferredLineLength` setting before, during, and
after installing this package. Note also that these changes are both global and grammar
specific.

## Future Work

- More spec test coverage.
- Up-to-date screenshots.

---

[MIT][mit] © [lexicalunit][author] et [al][contributors]

[mit]:                          http://opensource.org/licenses/MIT
[author]:                       http://github.com/lexicalunit
[contributors]:                 https://github.com/lexicalunit/multi-wrap-guide/graphs/contributors
[releases]:                     https://github.com/lexicalunit/multi-wrap-guide/releases
[mit-badge]:                    https://img.shields.io/apm/l/multi-wrap-guide.svg
[apm-pkg-link]:                 https://atom.io/packages/multi-wrap-guide
[apm-ver-link]:                 https://img.shields.io/apm/v/multi-wrap-guide.svg
[dl-badge]:                     http://img.shields.io/apm/dm/multi-wrap-guide.svg
[travis-ci-badge]:              https://travis-ci.org/lexicalunit/multi-wrap-guide.svg?branch=master
[travis-ci]:                    https://travis-ci.org/lexicalunit/multi-wrap-guide
[appveyor]:                     https://ci.appveyor.com/project/lexicalunit/multi-wrap-guide?branch=master
[appveyor-badge]:               https://ci.appveyor.com/api/projects/status/10nasryx3of9h2lp/branch/master?svg=true
[circle-ci]:                    https://circleci.com/gh/lexicalunit/multi-wrap-guide/tree/master
[circle-ci-badge]:              https://circleci.com/gh/lexicalunit/multi-wrap-guide/tree/master.svg?style=shield
[david-badge]:                  https://david-dm.org/lexicalunit/multi-wrap-guide.svg
[david]:                        https://david-dm.org/lexicalunit/multi-wrap-guide
[issues]:                       https://github.com/lexicalunit/multi-wrap-guide/issues
[img-colors]:                   https://cloud.githubusercontent.com/assets/1903876/8047181/b1ef283a-0e07-11e5-92b9-5c9afbebf29c.png
[img-create]:                   https://cloud.githubusercontent.com/assets/1903876/8047182/b1f6e340-0e07-11e5-8db5-99add2af6646.gif
[img-drag]:                     https://cloud.githubusercontent.com/assets/1903876/8047183/b1f95c24-0e07-11e5-9c53-d2e1ba4cd273.gif
[img-guides]:                   https://cloud.githubusercontent.com/assets/1903876/8047184/b1fc4a9c-0e07-11e5-943f-ebffd647c2e0.png
[language-specific-settings]:   http://blog.atom.io/2014/10/31/language-scoped-config.html
[line-length-break]:            https://atom.io/packages/line-length-break
