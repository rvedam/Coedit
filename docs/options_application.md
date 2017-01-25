---
title: Widgets - application options
---

#### Application

{% include xstyle.css %}

The page exposes unsorted options. In the future some of them might be moved to their own category.

![](img/options_application.png)

- **additionalPATH**: Used to defined more paths were the background tools can be found. Each item must be separated by a path separator (`:` under Linux and `;` under Windows).
- **autoCheckUpdates**: If checked and if a newer release is available then a dialog proposes to redirect to the release page on github.
- **autoSaveProjectFiles**: If checked the sources are automatically saved before compilation.
- **coverModuleTests**: If checked then the coverage by the tests is measured and displayed in the messages after executing the action __File/Run file unittests__.
- **dcdPort**: Sets the port used by the [completion daemon](feaures_dcd) server. `0` means the default value.
- **dscanUnuttests**: If checked the content of the `unittest` blocks are analyzed when using the action __File/Verify with Dscanner__.
- **flatLook**: Doesn't draw the buttons shape unless they're hovered by the mouse.
- **floatingWidgetOnTop**: Keeps the widgets that are not docked on top of the application window.
- **maxReventDocuments**: Sets how many entries can be stored in __File/Open recent file__.
- **maxReventDocuments**: Sets how many entries can be stored in __Project/Open recent project__.
- **maxReventProjectsGroups**: Sets how many entries can be stored in __Projects group/Open recent group__.
- **nativeProjectCompiler**: Sets [which compiler](options_compilers_paths) is used to compile a project that has the [CE format](widgets_ce_project_editor).
- **reloadLastDocuments**: Sets if the sources, the project, and the group that were opened on exit are reloaded automatically.
- **showBuildDUration**: Sets if the duration of a project build is measured.
- **splitterScrollSpeed**: Sets how fast the splitters are moved when using the scroll wheel.