## Design of a workspace 

### Domain 
- Deterministic vs Non-deterministic
- Context and memories 
- Workflows 
- Tools 
- Skills

### Tech 
- What tools are implemented 
  - CLI tools (System or installed)
  - Custom CLI tools 
- Cronjobs
- Pipelines (and state management)
- Tool Permissions - Overall 
- Tool Permissions - For the user (Multi-tenancy etc)
- Environment variables 
- Secret management 
- Observability
- Logging 


## Notes 

### Tool agnostic 
- Implementation 
  - Approach 1 : Symlinks
    - `~/.agent`
    - Create symlinks in other places
  - Approach 2 : Tools like `rulesync`

### Third party CLI tools 
- Should be implemented in a containerised environment. I would also like to see the data associated with the various tools. 
- Implementation 
  - Adding a new tool 
    - Check if the tool should be installed globally or for the user (Accordingly add in the relevant file)
    - Install the tool inside the container — its files will automatically persist in volumes/agent_machine/home/
    - Check what all environment variables are required for the tool to run 
    - Make sure that you are updating the PATH variable especially in case you are installing through a native installer (instead of node installation)

### Theory - Observability and self improvement 
- Why are we logging? 
  - Improve the AI agents (system prompt, deterministic tools etc) - Feedback loop 
  - Extract memories (Ideally should be manged within hooks itself)
- What are we logging? 
  - AI traces, tool calls etc 
  - Custom tool logs
    - API and CLI logs 
    - Manual logs 
- Implementation 
  - Approach 1 : Claude and Gemini etc save their traces in the home directory. Just use this for now
    - Where do they have 
      - `~/.claude/projects`
      - `~/.gemini/tmp`
      - `~/.regisedge/logs`
  - Approach 2 : Define hooks that looks at the logs, and passes the incremental data to an external server on the execution of the "stop" hook
  - Approach 3 : OpenTelemetry settings in environment variables before running claude that automatically sends data to an external server