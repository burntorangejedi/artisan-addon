# Tools README

This folder contains helper scripts for development and deployment of the Artisan addon.

Files
- `generate-fonts.ps1` — scans `media/` for `.ttf` font files and regenerates `fonts.lua`. Use this after adding or removing fonts so the addon will register them with LibSharedMedia.
- `deploy-addons.ps1` — copies the addon workspace into a World of Warcraft `Interface\AddOns` folder. Useful to quickly update your installed addon during development.

Usage

1) Regenerate fonts.lua after adding fonts

From the repository root run:

```powershell
pwsh.exe .\tools\generate-fonts.ps1
```

This will overwrite `fonts.lua` with a new registration table derived from the files in `media/`.

2) Deploy the addon to your WoW AddOns folder

Interactive mode (prompts for destination):

```powershell
pwsh.exe .\tools\deploy-addons.ps1
```

Non-interactive mode (pass explicit target):

```powershell
pwsh.exe .\tools\deploy-addons.ps1 -AddonName artisan-addon -Target "C:\Path\To\World of Warcraft\_retail_\Interface\AddOns"
```

Notes
- The deploy script will remove any existing folder with the same addon name before copying. If you want to preserve `SavedVariables`, edit the script to exclude that folder from deletion/copy.
- The generator script is needed because WoW's Lua runtime cannot enumerate the file system. The generator creates a Lua file that lists fonts to register at runtime.

VS Code Build task
- The workspace includes a Build task (Ctrl+Shift+B) that runs the deploy script. By default it runs the script interactively. If you prefer a fixed (non-interactive) deployment, modify `.vscode/tasks.json` to pass a `-Target` parameter.

Suggested improvements
- Add a git pre-commit hook to auto-run the font generator if fonts change.
- Add exclusions to the deploy script to avoid copying development-only files (e.g., `.git`, `tools`, `.vscode`) and to preserve `SavedVariables`.

If you want, I can update the deploy task to be non-interactive and targeted to a path you specify, or add the exclusions/preserve behavior — tell me which you'd prefer and I will implement it.
