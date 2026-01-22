---
name: create-term-project
description: Create WezTerm Project
allowed-tools: Bash, Write
---

# Create WezTerm Project

Create a `.wezterm/project.md` file in the current directory to configure the WezTerm tab title and color.

## Instructions

1. Ask the user for a **project name** (this will be the tab title)

2. Present these 5 color options and ask the user to choose one:
   - **Cyan** - #00CED1
   - **Coral** - #FF7F50
   - **Lime** - #32CD32
   - **Orchid** - #DA70D6
   - **Gold** - #FFD700

3. Create the `.wezterm` directory in the current working directory if it doesn't exist

4. Create `.wezterm/project.md` with:
   - Line 1: The project name
   - Line 2: The hex color code (e.g., #00CED1)

5. Confirm to the user that the file was created and what color/name was set

## Example Output File
```
My Project Name
#00CED1
```
