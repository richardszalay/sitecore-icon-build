[![Build status](https://ci.appveyor.com/api/projects/status/n1pnky311hnto0kk/branch/master?svg=true)](https://ci.appveyor.com/project/richardszalay/sitecore-icon-build/branch/master)

MSBuild extensions for building Sitecore icon zip archives and including them in the published website.

# Installation

`PM> Install-Package RichardSzalay.Sitecore.Icons.MSBuild`

# Usage

The targets support two different ways of defining icons, and they can be mixed and matched. Both 
methods use the folder structure `/sitecore/shell/Themes/Standard/[CustomSet]/` for defining custom 
icon sets.

The basic approach is to simply place 'master' images (128x128 recommended) in the custom set directory,
and they will be resized into the standard icon sizes during the build process.

This can be supplemented by placing individual images in the sized (eg. _16x16/_) subfolders. Any image in a 
sized folder will be used in preference to reszing the master image, and if all sized images are bespoke the master image can be omitted entirely.

Any number of custom icon set folders can be defined, and they can contain any combination of master vs sized icons.

Once pubished images can be referenced from Sitecore as `CustomSet/32x32/icon1.png`.

# Publishing

The generated zip files are automatically included in the publish pipeline, and the original source files are omitted from it.

All generated files are written to `obj/[Configuration]/sitecoreIcons/` so no additional version control ignore rules are required.

# Performance

The targets make use of the correct MSBuild features to ensure that any work (be it resizing or creating zip files) is only done when the source files have changed. For most scenarios it should have little to no impact on build speed.

# Development

The build process, including tests, can be run by cloning the repository and running:

```
Import-Module .\build\psake\psake.psd1
Invoke-psake
```