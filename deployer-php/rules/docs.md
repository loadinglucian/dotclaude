# Documentation Rules

Rules for writing DeployerPHP user documentation.

<rules>

- **No non-interactive command examples**: DeployerPHP commands display a "Non-interactive command replay" at the end of each execution. Don't duplicate this in docs—instead, mention that the replay is shown automatically.
- **Explain what commands do, not what they output**: Describe the prompts, steps, and outcomes in prose rather than showing verbose terminal output.
- **Keep it scannable**: Use bullet lists for prompts, numbered lists for sequential steps.

</rules>

<examples>

  <example name="command-replay-note">
```markdown
> [!NOTE]
> After each command, DeployerPHP displays a non-interactive command replay
> that includes all the options you selected. You can copy this command to
> repeat or automate the operation.
```
  </example>

  <example name="describe-prompts">
```markdown
DeployerPHP will prompt you for:

- **Server name** - A friendly name for your server (e.g., "production", "web1")
- **Host** - The IP address or hostname of your server
- **Port** - SSH port (default: 22)
```
  </example>

  <example name="describe-steps">
```markdown
The installation process will:

1. Update package lists and install base packages
2. Configure Nginx with a monitoring endpoint
3. Set up the firewall (UFW)
4. Install your chosen PHP version with selected extensions
```
  </example>

</examples>
