# Multi Wrap Guide

[![apm package][apm-ver-link]][releases]
[![travis-ci][travis-ci-badge]][travis-ci]
[![appveyor][appveyor-badge]][appveyor]
[![circle-ci][circle-ci-badge]][circle-ci]
[![david][david-badge]][david]
[![download][dl-badge]][apm-pkg-link]
[![mit][mit-badge]][mit]
[![All Contributors][contributors]](#contributors)

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

## Contributors

Thanks goes to these wonderful people ([emoji key](https://github.com/kentcdodds/all-contributors#emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
| [<img src="https://avatars1.githubusercontent.com/u/1903876?v=4" width="100px;"/><br /><sub>Amy Troschinetz</sub>](http://lexicalunit.com)<br />[🐛](https://github.com/lexicalunit/multi-wrap-guide/issues?q=author%3Alexicalunit "Bug reports") [💻](https://github.com/lexicalunit/multi-wrap-guide/commits?author=lexicalunit "Code") [📖](https://github.com/lexicalunit/multi-wrap-guide/commits?author=lexicalunit "Documentation") | [<img src="https://avatars2.githubusercontent.com/u/281467?v=4" width="100px;"/><br /><sub>Chris Tonkinson</sub>](http://chris.tonkinson.com/)<br />[🐛](https://github.com/lexicalunit/multi-wrap-guide/issues?q=author%3Acmtonkinson "Bug reports") | [<img src="https://avatars3.githubusercontent.com/u/7296578?v=4" width="100px;"/><br /><sub>Jackson Bailey</sub>](https://github.com/JacksonBailey)<br />[🐛](https://github.com/lexicalunit/multi-wrap-guide/issues?q=author%3AJacksonBailey "Bug reports") | [<img src="https://avatars1.githubusercontent.com/u/383250?v=4" width="100px;"/><br /><sub>Jean Mertz</sub>](https://github.com/JeanMertz)<br />[🐛](https://github.com/lexicalunit/multi-wrap-guide/issues?q=author%3AJeanMertz "Bug reports") | [<img src="https://avatars2.githubusercontent.com/u/3522333?v=4" width="100px;"/><br /><sub>Sami Kankaristo</sub>](http://indiumgames.fi)<br />[🐛](https://github.com/lexicalunit/multi-wrap-guide/issues?q=author%3Akankaristo "Bug reports") | [<img src="https://avatars2.githubusercontent.com/u/16280491?v=4" width="100px;"/><br /><sub>Pete Hanson</sub>](http://pdxwolfy.org)<br />[🐛](https://github.com/lexicalunit/multi-wrap-guide/issues?q=author%3Apdxwolfy "Bug reports") | [<img src="https://avatars0.githubusercontent.com/u/8146593?v=4" width="100px;"/><br /><sub>Ped</sub>](https://pedzed.com)<br />[🐛](https://github.com/lexicalunit/multi-wrap-guide/issues?q=author%3Apedzed "Bug reports") |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| [<img src="https://avatars1.githubusercontent.com/u/9031092?v=4" width="100px;"/><br /><sub>Phoenix C. Enero</sub>](http://coreleaf.net)<br />[🐛](https://github.com/lexicalunit/multi-wrap-guide/issues?q=author%3Aphoenixenero "Bug reports") | [<img src="https://avatars1.githubusercontent.com/u/532414?v=4" width="100px;"/><br /><sub>Jesús Leganés-Combarro</sub>](http://pirannafs.blogspot.com)<br />[🐛](https://github.com/lexicalunit/multi-wrap-guide/issues?q=author%3Apiranna "Bug reports") | [<img src="https://avatars3.githubusercontent.com/u/11966684?v=4" width="100px;"/><br /><sub>rugk</sub>](https://github.com/rugk)<br />[🐛](https://github.com/lexicalunit/multi-wrap-guide/issues?q=author%3Arugk "Bug reports") | [<img src="https://avatars3.githubusercontent.com/u/1092618?v=4" width="100px;"/><br /><sub>Ryan Sawhill Aroha</sub>](http://people.redhat.com/rsawhill)<br />[🐛](https://github.com/lexicalunit/multi-wrap-guide/issues?q=author%3Aryran "Bug reports") | [<img src="https://avatars2.githubusercontent.com/u/6829403?v=4" width="100px;"/><br /><sub>GU Xiaojun</sub>](https://github.com/X-G)<br />[🐛](https://github.com/lexicalunit/multi-wrap-guide/issues?q=author%3AX-G "Bug reports") | [<img src="https://avatars0.githubusercontent.com/u/320562?v=4" width="100px;"/><br /><sub>Mark Kahn</sub>](https://github.com/zyklus)<br />[🐛](https://github.com/lexicalunit/multi-wrap-guide/issues?q=author%3Azyklus "Bug reports") | [<img src="https://avatars0.githubusercontent.com/u/153219?v=4" width="100px;"/><br /><sub>Adam Malcontenti-Wilson</sub>](http://adammw.it.cx)<br />[🐛](https://github.com/lexicalunit/multi-wrap-guide/issues?q=author%3Aadammw "Bug reports") |
<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://github.com/kentcdodds/all-contributors) specification. Contributions of any kind welcome!

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
[contributors]:                 https://img.shields.io/badge/all_contributors-0-orange.svg?style=shield
