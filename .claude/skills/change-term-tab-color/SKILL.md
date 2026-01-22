---
name: change-term-tab-color
description: Change WezTerm Tab Color
allowed-tools: Read, Write
---

# Change WezTerm Tab Color

Change the color in the existing `.wezterm/project.md` file.

## Instructions

1. First, check if `.wezterm/project.md` exists in the current directory
   - If it doesn't exist, tell the user to run `/create-term-project` first

2. Read the current `.wezterm/project.md` to get the current project name (line 1) and color (line 2)

3. Show the user the current color and present these 5 color options:
   - **Cyan** - #00CED1
   - **Coral** - #FF7F50
   - **Lime** - #32CD32
   - **Orchid** - #DA70D6
   - **Gold** - #FFD700

4. Ask the user to choose a new color

5. Update `.wezterm/project.md` keeping the project name on line 1 but replacing line 2 with the new color code

6. Confirm the color change to the user
