---
name: change-term-tab-name
description: Change WezTerm Tab Name
allowed-tools: Read, Write
---

# Change WezTerm Tab Name

Change the project name (tab title) in the existing `.wezterm/project.md` file.

## Instructions

1. First, check if `.wezterm/project.md` exists in the current directory
   - If it doesn't exist, tell the user to run `/create-term-project` first

2. Read the current `.wezterm/project.md` to get the current project name (line 1) and color (line 2)

3. Show the user the current name and ask what they want to change it to

4. Update `.wezterm/project.md` keeping the color on line 2 but replacing line 1 with the new project name

5. Confirm the name change to the user
