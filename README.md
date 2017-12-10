MSBuild extensions for building Sitecore icon zip archives and including them when publishing.

Icons that match the following structure will automatically be packaged:

```
/sitecore/shell/Themes/Standard/[IconSet]/[size]/icon.png
```

For example:

```
/sitecore/shell/Themes/Standard/CustomSet/16x16/icon1.png
/sitecore/shell/Themes/Standard/CustomSet/16x16/icon2.png
/sitecore/shell/Themes/Standard/CustomSet/32x32/icon1.png
/sitecore/shell/Themes/Standard/CustomSet/32x32/icon2.png
```

Will produce `/sitecore/shell/Themes/Standard/CustomSet.zip` when published.