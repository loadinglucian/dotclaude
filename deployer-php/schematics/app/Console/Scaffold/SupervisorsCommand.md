# SupervisorsCommand

Scaffolds supervisor program scripts from templates to the project's `.deployer/supervisors/` directory.

## Purpose

Copies pre-built supervisor script templates (queue workers, messenger consumers) to a user-specified project directory, enabling quick setup of background process configuration for deployment.

## Flow

```
execute()
    -> h1() display header
    -> scaffoldFiles('supervisors')
        -> promptDestinationDirectory() [ScaffoldsTrait]
            -> getValidatedOptionOrPrompt('destination')
            -> expandPath() + absolute path conversion
        -> resolveScaffoldContext() [default: returns []]
        -> buildTargetPath() [default: {dest}/.deployer/supervisors]
        -> copyTemplates()
            -> mkdir() if needed
            -> buildTemplatePath() -> scaffolds/supervisors/
            -> scanDirectory() templates
            -> foreach: skip dirs, skip existing, dumpFile() new
        -> displayDeets(status)
        -> yay() success
        -> commandReplay()
```

## Dependencies

| Dependency          | Purpose                                |
| ------------------- | -------------------------------------- |
| ScaffoldsTrait      | Template method pattern implementation |
| PathOperationsTrait | Path validation helpers                |
| FilesystemService   | File operations (via $this->fs)        |
| IoService           | Input/output (via $this->io)           |

## Dependents

None - standalone command invoked by users.

## Key Behaviors

1. **Destination validation**: Uses `validatePathInput()` - checks string, non-empty
2. **Path expansion**: Tilde expansion and relative-to-absolute conversion
3. **Skip existing files**: Won't overwrite files that already exist (including symlinks)
4. **Subdirectory skip**: Template subdirectories are not recursed - only top-level files copied

## Templates

- `scaffolds/supervisors/messenger.sh` - Symfony Messenger consumer
- `scaffolds/supervisors/queue-worker.sh` - Laravel queue worker

## CLI Options

| Option          | Type           | Source         |
| --------------- | -------------- | -------------- |
| `--destination` | VALUE_REQUIRED | ScaffoldsTrait |
| `--env`         | VALUE_OPTIONAL | BaseCommand    |
| `--inventory`   | VALUE_OPTIONAL | BaseCommand    |

## Edge Cases

- Empty templates directory: Returns empty status array, displays nothing
- Destination doesn't exist: Created automatically by `copyTemplates()`
- File already exists: Marked as "skipped" in status
- Symlink exists: Treated as existing, skipped
