-- WezTerm Configuration for Multi-Agent Development Workflow
-- Hot-reload enabled: save this file and changes apply immediately
-- Location: ~/.quetrexterm.lua (macOS) or ~/.config/quetrexterm/quetrexterm.lua

local quetrexterm = require 'quetrexterm'
local mux = quetrexterm.mux
local act = quetrexterm.action

local config = {}

-- ============================================================================
-- APPEARANCE - Classic Green Terminal (Easy on the eyes)
-- ============================================================================
config.font = quetrexterm.font('JetBrains Mono', { weight = 'Bold' })
config.font_size = 20.0
config.line_height = 1.3

-- Pure bright green terminal colors
config.colors = {
  foreground = '#00FF00',      -- Pure bright green text
  background = '#000000',      -- Pure black background
  cursor_bg = '#00FF00',
  cursor_fg = '#000000',

  -- ANSI color palette (what apps like Claude Code actually use)
  ansi = {
    '#000000',  -- black
    '#ff5555',  -- red
    '#00FF00',  -- green (pure bright green)
    '#f1fa8c',  -- yellow
    '#6272a4',  -- blue
    '#ff79c6',  -- magenta
    '#8be9fd',  -- cyan
    '#f8f8f2',  -- white
  },
  brights = {
    '#44475a',  -- bright black
    '#ff6e6e',  -- bright red
    '#00FF00',  -- bright green (same pure green)
    '#ffffa5',  -- bright yellow
    '#d6acff',  -- bright blue
    '#ff92df',  -- bright magenta
    '#a4ffff',  -- bright cyan
    '#ffffff',  -- bright white
  },

  -- Tab bar colors
  tab_bar = {
    background = '#000000',
    active_tab = {
      bg_color = '#003300',
      fg_color = '#00FF00',
    },
    inactive_tab = {
      bg_color = '#000000',
      fg_color = '#008800',
    },
    new_tab = {
      bg_color = '#000000',
      fg_color = '#00FF00',
    },
  },
}

-- Window
config.window_decorations = "RESIZE"
config.window_background_opacity = 1.0  -- Solid black for contrast
config.window_padding = { left = 12, right = 12, top = 12, bottom = 12 }

-- Tab bar (fancy style - has close buttons)
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 48

-- Tab bar font size
config.window_frame = {
  font = quetrexterm.font('JetBrains Mono', { weight = 'Bold' }),
  font_size = 20.0,
}

-- ============================================================================
-- PROJECTS CONFIGURATION
-- Define your projects here - each can have custom setup commands
-- ============================================================================
local projects = {
  {
    name = "Quetrex",
    path = "~/projects/quetrex",
    -- Commands to run when tab opens (executed in sequence)
    setup_commands = {
      "git fetch --all",
      "echo '🚀 Quetrex ready'",
    },
    -- Agent command (leave empty to just get a shell)
    agent_command = "claude",  -- or "cursor", "aider", etc.
  },
  {
    name = "FreelanzDesk",
    path = "~/projects/freelanzdesk",
    setup_commands = {
      "git fetch --all",
    },
    agent_command = "claude",
  },
  {
    name = "Client Project",
    path = "~/projects/client",
    setup_commands = {
      "git fetch --all",
      "nvm use",  -- if using node version manager
    },
    agent_command = "",
  },
}

-- ============================================================================
-- GIT WORKTREE SUPPORT
-- Creates a new worktree for isolated agent work
-- ============================================================================
local function create_worktree_command(branch_name, base_path)
  return string.format([[
    cd %s && \
    BRANCH="%s" && \
    WORKTREE_PATH="../worktrees/$BRANCH" && \
    git worktree add "$WORKTREE_PATH" -b "$BRANCH" 2>/dev/null || \
    git worktree add "$WORKTREE_PATH" "$BRANCH" && \
    cd "$WORKTREE_PATH" && \
    echo "📂 Worktree ready: $WORKTREE_PATH"
  ]], base_path, branch_name)
end

-- ============================================================================
-- SPAWN AGENT TAB FUNCTION
-- Core function that creates a new tab with full agent setup
-- ============================================================================
local function spawn_agent_tab(window, pane, project, use_worktree, branch_name)
  -- Expand ~ to home directory
  local path = project.path:gsub("^~", os.getenv("HOME"))
  
  -- Spawn new tab
  local tab, new_pane, _ = window:mux_window():spawn_tab {
    cwd = path,
  }
  
  -- Set tab title
  tab:set_title(project.name)
  
  -- Build setup script
  local setup_script = ""
  
  -- If using worktree, set that up first
  if use_worktree and branch_name then
    setup_script = create_worktree_command(branch_name, path) .. " && "
  end
  
  -- Add project setup commands
  for _, cmd in ipairs(project.setup_commands or {}) do
    setup_script = setup_script .. cmd .. " && "
  end
  
  -- Add agent command if specified
  if project.agent_command and project.agent_command ~= "" then
    setup_script = setup_script .. project.agent_command
  else
    -- Just clear and show ready message
    setup_script = setup_script .. "clear && echo '✅ Ready for work'"
  end
  
  -- Send the commands to the new pane
  new_pane:send_text(setup_script .. "\n")
  
  return tab, new_pane
end

-- ============================================================================
-- PROJECT SELECTOR
-- Shows a picker to choose which project to open
-- ============================================================================
local function project_selector(window, pane)
  local choices = {}
  
  for _, project in ipairs(projects) do
    table.insert(choices, {
      id = project.name,
      label = string.format("🚀 %s (%s)", project.name, project.path),
    })
  end
  
  -- Add worktree option
  table.insert(choices, {
    id = "__worktree__",
    label = "📂 New Worktree (enter branch name)",
  })
  
  window:perform_action(
    act.InputSelector {
      title = "Select Project",
      choices = choices,
      action = quetrexterm.action_callback(function(inner_window, inner_pane, id, label)
        if not id then return end
        
        if id == "__worktree__" then
          -- Prompt for branch name, then project
          inner_window:perform_action(
            act.PromptInputLine {
              description = "Enter branch name for worktree:",
              action = quetrexterm.action_callback(function(w, p, branch)
                if branch and branch ~= "" then
                  -- Now select project for worktree
                  local proj_choices = {}
                  for _, proj in ipairs(projects) do
                    table.insert(proj_choices, { id = proj.name, label = proj.name })
                  end
                  w:perform_action(
                    act.InputSelector {
                      title = "Select project for worktree",
                      choices = proj_choices,
                      action = quetrexterm.action_callback(function(w2, p2, proj_id)
                        if proj_id then
                          for _, proj in ipairs(projects) do
                            if proj.name == proj_id then
                              spawn_agent_tab(w2, p2, proj, true, branch)
                              break
                            end
                          end
                        end
                      end),
                    },
                    p
                  )
                end
              end),
            },
            inner_pane
          )
        else
          -- Regular project spawn
          for _, project in ipairs(projects) do
            if project.name == id then
              spawn_agent_tab(inner_window, inner_pane, project, false, nil)
              break
            end
          end
        end
      end),
    },
    pane
  )
end

-- ============================================================================
-- QUICK AGENT SPAWN
-- Spawns agent tab for first project immediately (fastest workflow)
-- ============================================================================
local function quick_spawn_agent(window, pane)
  if #projects > 0 then
    spawn_agent_tab(window, pane, projects[1], false, nil)
  end
end

-- ============================================================================
-- KEY BINDINGS
-- ============================================================================
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

config.keys = {
  -- ==========================================================================
  -- AGENT WORKFLOW KEYS
  -- ==========================================================================
  
  -- CMD+SHIFT+A: Open project selector (pick project, optionally create worktree)
  {
    key = 'a',
    mods = 'CMD|SHIFT',
    action = quetrexterm.action_callback(project_selector),
  },
  
  -- CMD+SHIFT+N: Quick spawn - immediately opens first project with agent
  {
    key = 'n',
    mods = 'CMD|SHIFT',
    action = quetrexterm.action_callback(quick_spawn_agent),
  },
  
  -- LEADER + 1-9: Quick access to specific projects
  { key = '1', mods = 'LEADER', action = quetrexterm.action_callback(function(w, p)
    if projects[1] then spawn_agent_tab(w, p, projects[1], false, nil) end
  end)},
  { key = '2', mods = 'LEADER', action = quetrexterm.action_callback(function(w, p)
    if projects[2] then spawn_agent_tab(w, p, projects[2], false, nil) end
  end)},
  { key = '3', mods = 'LEADER', action = quetrexterm.action_callback(function(w, p)
    if projects[3] then spawn_agent_tab(w, p, projects[3], false, nil) end
  end)},
  
  -- ==========================================================================
  -- TAB NAVIGATION
  -- ==========================================================================
  { key = 'h', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = 'l', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(1) },
  
  -- CMD + number to jump to tab
  { key = '1', mods = 'CMD', action = act.ActivateTab(0) },
  { key = '2', mods = 'CMD', action = act.ActivateTab(1) },
  { key = '3', mods = 'CMD', action = act.ActivateTab(2) },
  { key = '4', mods = 'CMD', action = act.ActivateTab(3) },
  { key = '5', mods = 'CMD', action = act.ActivateTab(4) },
  { key = '6', mods = 'CMD', action = act.ActivateTab(5) },
  { key = '7', mods = 'CMD', action = act.ActivateTab(6) },
  { key = '8', mods = 'CMD', action = act.ActivateTab(7) },
  { key = '9', mods = 'CMD', action = act.ActivateTab(-1) }, -- Last tab
  
  -- ==========================================================================
  -- SPLITS
  -- ==========================================================================
  { key = 'd', mods = 'CMD', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'CMD|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  
  -- Navigate splits
  { key = 'LeftArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Down' },
  
  -- ==========================================================================
  -- UTILITY
  -- ==========================================================================
  { key = 'r', mods = 'CMD|SHIFT', action = act.ReloadConfiguration },
  { key = 'p', mods = 'CMD|SHIFT', action = act.ActivateCommandPalette },
  { key = 'f', mods = 'CMD|SHIFT', action = act.Search { CaseInSensitiveString = '' } },

  -- ==========================================================================
  -- WORKSPACE MANAGEMENT
  -- ==========================================================================

  -- CMD+SHIFT+W: Create new named workspace
  {
    key = 'w',
    mods = 'CMD|SHIFT',
    action = act.PromptInputLine {
      description = quetrexterm.format {
        { Foreground = { Color = '#00FF00' } },
        { Text = 'Enter name for new workspace:' },
      },
      action = quetrexterm.action_callback(function(window, pane, line)
        if line and line ~= '' then
          window:perform_action(
            act.SwitchToWorkspace {
              name = line,
              spawn = { label = 'Workspace: ' .. line },
            },
            pane
          )
        end
      end),
    },
  },

  -- CMD+SHIFT+Arrow: Navigate between workspaces
  { key = 'LeftArrow', mods = 'CMD|SHIFT', action = act.SwitchWorkspaceRelative(-1) },
  { key = 'RightArrow', mods = 'CMD|SHIFT', action = act.SwitchWorkspaceRelative(1) },

  -- CMD+SHIFT+S: Workspace picker (fuzzy switch)
  { key = 's', mods = 'CMD|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },

  -- CMD+SHIFT+M: Rename current workspace
  {
    key = 'm',
    mods = 'CMD|SHIFT',
    action = act.PromptInputLine {
      description = quetrexterm.format {
        { Foreground = { Color = '#00FF00' } },
        { Text = 'Rename workspace to:' },
      },
      action = quetrexterm.action_callback(function(window, pane, line)
        if line and line ~= '' then
          local current = window:active_workspace()
          quetrexterm.mux.rename_workspace(current, line)
        end
      end),
    },
  },
}

-- ============================================================================
-- STARTUP SESSION (Optional)
-- Uncomment to auto-spawn tabs on launch
-- ============================================================================
-- quetrexterm.on('gui-startup', function(cmd)
--   local tab, pane, window = mux.spawn_window(cmd or {})
--   
--   -- Spawn additional agent tabs on startup
--   for i, project in ipairs(projects) do
--     if i <= 3 then  -- Limit to first 3 projects
--       spawn_agent_tab(window, pane, project, false, nil)
--     end
--   end
-- end)

-- ============================================================================
-- TAB TITLE FORMATTING
-- Reads title from .quetrexterm/project.md in current directory, falls back to pane title
-- ============================================================================

-- Helper function to read project title from .quetrexterm/project.md
local function get_project_title(cwd)
  if not cwd or cwd == '' then
    return nil
  end
  local project_file = cwd .. '/.quetrexterm/project.md'
  local ok, file = pcall(io.open, project_file, 'r')
  if ok and file then
    local first_line = file:read('*line')
    file:close()
    if first_line then
      -- Remove markdown heading prefix (# ) if present
      local title = first_line:gsub('^#%s*', '')
      if title and #title > 0 then
        return title
      end
    end
  end
  return nil
end

-- Helper function to read project color from line 2 of .quetrexterm/project.md
local function get_project_color(cwd)
  if not cwd or cwd == '' then
    return nil
  end
  local project_file = cwd .. '/.quetrexterm/project.md'
  local ok, file = pcall(io.open, project_file, 'r')
  if ok and file then
    local first_line = file:read('*line')  -- skip first line
    local second_line = file:read('*line')
    file:close()
    if second_line then
      -- Check if it looks like a hex color
      local color = second_line:match('^#%x%x%x%x%x%x$')
      if color then
        return color
      end
    end
  end
  return nil
end

-- Agent colors for fallback when no project.md exists
local agent_colors = {
  ORCHESTRATOR = '#3b82f6',  -- Blue
  DEVELOPER = '#22c55e',     -- Green
  DEV = '#22c55e',           -- Green
  ['TEST-RUNNER'] = '#eab308', -- Yellow
  TEST = '#eab308',          -- Yellow
  ['QA-FIXER'] = '#ef4444',  -- Red
  FIX = '#ef4444',           -- Red
  REVIEWER = '#a855f7',      -- Purple
  REVIEW = '#a855f7',        -- Purple
  ARCHITECT = '#06b6d4',     -- Cyan
  DESIGNER = '#ec4899',      -- Pink
  SECURITY = '#f97316',      -- Orange
}

-- Helper to detect agent type from title
local function get_agent_color(title)
  if not title then return nil end
  local upper_title = title:upper()
  for agent, color in pairs(agent_colors) do
    if upper_title:find(agent, 1, true) then
      return color
    end
  end
  return nil
end

quetrexterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  -- Get the current working directory
  local cwd_url = tab.active_pane.current_working_dir
  local title = nil
  local color = nil
  local default_color = '#00FF00'  -- Pure bright green default

  -- Try to read from project.md
  if cwd_url then
    local path
    -- Handle both URL object and string formats
    if type(cwd_url) == 'userdata' or type(cwd_url) == 'table' then
      path = cwd_url.file_path
    elseif type(cwd_url) == 'string' then
      path = cwd_url:gsub('^file://[^/]*', '')
    end
    if path then
      title = get_project_title(path)
      color = get_project_color(path)
    end
  end

  -- Fallback to running process name or tab title
  if not title or #title == 0 then
    -- Check if tab has a custom title (set by agent spawn)
    if tab.tab_title and tab.tab_title ~= '' then
      title = tab.tab_title
    else
      -- Try to get the foreground process name
      local process = tab.active_pane.foreground_process_name
      if process and process ~= '' then
        local process_name = process:match('([^/]+)$')
        if process_name and process_name ~= '' then
          title = process_name
        end
      end
    end

    -- Final fallback to Terminal
    if not title or title == '' then
      title = 'Terminal'
    end
  end

  -- If no project color, check for agent color based on title
  if not color then
    color = get_agent_color(title) or default_color
  end

  -- Tab styling:
  -- Active tab: Green dot indicator with project/agent color text
  -- Inactive tab: Project/agent color text
  if tab.is_active then
    return {
      { Foreground = { Color = color } },
      { Text = string.format(' ● %s ', title) },
    }
  else
    -- Inactive tabs get colored text (project color)
    return {
      { Foreground = { Color = color } },
      { Text = string.format('   %s ', title) },
    }
  end
end)

-- ============================================================================
-- STATUS BAR (Right side)
-- Shows current workspace info
-- ============================================================================
quetrexterm.on('update-right-status', function(window, pane)
  local date = quetrexterm.strftime '%H:%M'
  local workspace = window:active_workspace()
  local workspace_count = #quetrexterm.mux.get_workspace_names()

  local ws_display = workspace_count > 1
    and string.format('[%s] (%d)', workspace, workspace_count)
    or string.format('[%s]', workspace)

  window:set_right_status(quetrexterm.format {
    { Foreground = { Color = '#00FF00' } },
    { Text = string.format(' %s | %s ', ws_display, date) },
  })
end)

-- Prevent multiple windows on startup
quetrexterm.on('gui-attached', function(domain)
  -- Just attach to existing GUI, don't spawn extra windows
end)

return config
