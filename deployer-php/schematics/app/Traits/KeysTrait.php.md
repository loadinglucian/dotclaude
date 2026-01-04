# Schematic: KeysTrait.php

> Auto-generated schematic. Last updated: 2025-12-18

## Overview

KeysTrait provides reusable SSH key validation and resolution functionality for commands that work with SSH keys. It handles key path resolution with fallback defaults, validates both public and private key formats, and provides interactive prompts for key selection. The trait requires `FilesystemService` and `IoService` to be available on the using class.

## Logic Flow

### Entry Points

| Method | Purpose | Access |
|--------|---------|--------|
| `resolvePrivateKeyPath()` | Resolve private key with fallback to defaults | protected |
| `resolvePublicKeyPath()` | Resolve public key with fallback to defaults | protected |
| `promptDeployKeyPairPath()` | Interactive prompt for deploy key pair | protected |
| `promptPrivateKeyPath()` | Interactive prompt for private key | protected |
| `validateDeployKeyPairInput()` | Validate deploy key pair (private + public) | protected |
| `validateKeyNameInput()` | Validate SSH key name format | protected |
| `validateKeyPathInput()` | Validate public key file | protected |
| `validatePrivateKeyPathInput()` | Validate private key file | protected |
| `validatePrivateKeyPathInputAllowEmpty()` | Validate private key (empty allowed) | protected |

### Execution Flow

#### Key Resolution Flow

```
resolvePrivateKeyPath(path)
    |
    v
resolveKeyWithFallback(path, [~/.ssh/id_ed25519, ~/.ssh/id_rsa])
    |
    v
FilesystemService::getFirstExisting(candidates)
    |
    v
Return first existing path or null
```

#### Deploy Key Pair Prompt Flow

```
promptDeployKeyPairPath()
    |
    v
IoService::getValidatedOptionOrPrompt('custom-deploy-key', ...)
    |
    +-- Interactive: promptText with validateDeployKeyPairInput
    |
    +-- CLI: Validate --custom-deploy-key option
    |
    v
validateDeployKeyPairInput(path)
    |
    +-- validatePrivateKeyPathInput(path)
    |   |
    |   +-- Check type, non-empty, exists, PEM format
    |
    +-- validateKeyPathInput(path + '.pub')
        |
        +-- Check exists, valid SSH public key format
    |
    v
FilesystemService::expandPath(path)
    |
    v
Return expanded path
```

#### Private Key Validation Flow

```
validatePrivateKeyPathInput(path)
    |
    +-- Type check (must be string)
    |
    +-- Empty check (cannot be empty)
    |
    +-- FilesystemService::expandPath(path)
    |
    +-- FilesystemService::exists(expandedPath)
    |
    +-- FilesystemService::readFile(expandedPath)
    |
    +-- Format validation (PEM headers)
    |   |
    |   +-- BEGIN OPENSSH PRIVATE KEY
    |   +-- BEGIN RSA PRIVATE KEY
    |   +-- BEGIN EC PRIVATE KEY
    |   +-- BEGIN PRIVATE KEY
    |   +-- BEGIN DSA PRIVATE KEY (rejected as obsolete)
    |
    v
Return null (valid) or error message
```

### Decision Points

| Location | Condition | True Path | False Path |
|----------|-----------|-----------|------------|
| `resolveKeyWithFallback` L44 | Path provided and non-empty | Add to candidates | Skip |
| `validateKeyPathInput` L223 | Path is empty string | Return null (allow empty) | Continue validation |
| `validateKeyPathInput` L267 | Key is DSA type | Return specific DSA error | Return generic format error |
| `validatePrivateKeyPathInputAllowEmpty` L355 | Path is empty | Return null (allow) | Delegate to `validatePrivateKeyPathInput` |

### Exit Conditions

| Method | Success Return | Failure Return |
|--------|----------------|----------------|
| `resolveKeyWithFallback` | Expanded path string | `null` |
| `resolvePrivateKeyPath` | Expanded path string | `null` |
| `resolvePublicKeyPath` | Expanded path string | `null` |
| `promptDeployKeyPairPath` | Expanded path string | Throws `ValidationException` |
| `promptPrivateKeyPath` | Resolved path string | Throws `ValidationException` |
| `validate*Input` methods | `null` (valid) | Error message string |

## Interaction Diagram

```mermaid
flowchart TD
    subgraph Commands["Consuming Commands"]
        SAC[ServerAddCommand]
        SIC[ServerInstallCommand]
        SPDO[ServerProvisionDigitalOceanCommand]
        KADO[KeyAddDigitalOceanCommand]
        KDDO[KeyDeleteDigitalOceanCommand]
    end

    subgraph KeysTrait["KeysTrait"]
        subgraph Helpers["Key Resolution"]
            RKF[resolveKeyWithFallback]
            RPK[resolvePrivateKeyPath]
            RPUK[resolvePublicKeyPath]
        end

        subgraph UI["User Interface"]
            PDKP[promptDeployKeyPairPath]
            PPKP[promptPrivateKeyPath]
        end

        subgraph Validation["Validators"]
            VDKP[validateDeployKeyPairInput]
            VKN[validateKeyNameInput]
            VKP[validateKeyPathInput]
            VPKP[validatePrivateKeyPathInput]
            VPKPAE[validatePrivateKeyPathInputAllowEmpty]
        end
    end

    subgraph Services["Services"]
        FS[FilesystemService]
        IO[IoService]
    end

    subgraph Exceptions["Exceptions"]
        VE[ValidationException]
    end

    %% Command usage
    SAC --> PPKP
    SIC --> PDKP
    SPDO --> PPKP
    KADO --> VKP
    KADO --> VKN
    KADO --> RPUK

    %% Internal flow
    RPK --> RKF
    RPUK --> RKF
    RKF --> FS

    PDKP --> IO
    PDKP --> VDKP
    PDKP --> FS
    PPKP --> IO
    PPKP --> VPKPAE
    PPKP --> RPK
    PPKP -.-> VE

    VDKP --> VPKP
    VDKP --> VKP
    VPKPAE --> VPKP
    VPKP --> FS
    VKP --> FS
```

## Dependencies

### Direct Imports

| File/Class | Usage |
|------------|-------|
| `Deployer\Exceptions\ValidationException` | Thrown when prompts fail validation |
| `Deployer\Services\FilesystemService` | File existence, path expansion, reading key content |
| `Deployer\Services\IoService` | Interactive prompts via `getValidatedOptionOrPrompt` |

### Coupled Files

| File | Coupling Type | Description |
|------|---------------|-------------|
| `app/Contracts/BaseCommand.php` | State | Commands using this trait extend BaseCommand which provides `$this->io` and `$this->fs` |
| `~/.ssh/id_ed25519` | Data | Default Ed25519 private key fallback location |
| `~/.ssh/id_ed25519.pub` | Data | Default Ed25519 public key fallback location |
| `~/.ssh/id_rsa` | Data | Default RSA private key fallback location |
| `~/.ssh/id_rsa.pub` | Data | Default RSA public key fallback location |

### Commands Using This Trait

| Command | Methods Used |
|---------|--------------|
| `ServerAddCommand` | `promptPrivateKeyPath()` |
| `ServerInstallCommand` | `promptDeployKeyPairPath()` |
| `ServerProvisionDigitalOceanCommand` | `promptPrivateKeyPath()` |
| `KeyAddDigitalOceanCommand` | `validateKeyPathInput()`, `validateKeyNameInput()`, `resolvePublicKeyPath()` |
| `KeyDeleteDigitalOceanCommand` | Uses trait but no direct method calls visible in execute() |

## Data Flow

### Inputs

| Method | Input Type | Source |
|--------|------------|--------|
| `resolveKeyWithFallback` | `?string $path`, `array $fallback` | Calling method |
| `resolvePrivateKeyPath` | `?string $path` | CLI option or prompt |
| `resolvePublicKeyPath` | `?string $path` | CLI option or prompt |
| `promptDeployKeyPairPath` | None (reads `--custom-deploy-key`) | CLI option or interactive prompt |
| `promptPrivateKeyPath` | None (reads `--private-key-path`) | CLI option or interactive prompt |
| `validate*` methods | `mixed $path` or `mixed $name` | CLI option value or prompt result |

### Outputs

| Method | Output Type | Destination |
|--------|-------------|-------------|
| `resolveKeyWithFallback` | `?string` | Calling method |
| `resolvePrivateKeyPath` | `?string` | Command for SSH connection setup |
| `resolvePublicKeyPath` | `?string` | Command for key upload |
| `promptDeployKeyPairPath` | `string` | ServerInstallCommand for deploy key setup |
| `promptPrivateKeyPath` | `string` | Command for SSH connection |
| `validate*` methods | `?string` | IoService for validation feedback |

### Side Effects

None. This trait is stateless and performs only read operations on the filesystem.

## Supported Key Types

### Public Keys (validateKeyPathInput)

| Type | Prefix | Status |
|------|--------|--------|
| Ed25519 | `ssh-ed25519` | Supported |
| ECDSA NIST P-256 | `ecdsa-sha2-nistp256` | Supported |
| ECDSA NIST P-384 | `ecdsa-sha2-nistp384` | Supported |
| ECDSA NIST P-521 | `ecdsa-sha2-nistp521` | Supported |
| RSA | `ssh-rsa` | Supported |
| FIDO2 Ed25519 | `sk-ssh-ed25519@openssh.com` | Supported |
| FIDO2 ECDSA | `sk-ecdsa-sha2-nistp256@openssh.com` | Supported |
| DSA | `ssh-dss` | Rejected (obsolete) |

### Private Keys (validatePrivateKeyPathInput)

| Type | PEM Header | Status |
|------|------------|--------|
| OpenSSH | `-----BEGIN OPENSSH PRIVATE KEY-----` | Supported |
| RSA | `-----BEGIN RSA PRIVATE KEY-----` | Supported |
| EC | `-----BEGIN EC PRIVATE KEY-----` | Supported |
| Generic | `-----BEGIN PRIVATE KEY-----` | Supported |
| DSA | `-----BEGIN DSA PRIVATE KEY-----` | Rejected (obsolete) |

## CLI Options Integration

| Option Name | Method | Behavior |
|-------------|--------|----------|
| `--custom-deploy-key` | `promptDeployKeyPairPath()` | Path to private key; public key expected at path + `.pub` |
| `--private-key-path` | `promptPrivateKeyPath()` | Path to private key with fallback to defaults |
| `--public-key-path` | Used via `validateKeyPathInput()` | Path to public key with fallback to defaults |
| `--name` | Used via `validateKeyNameInput()` | Key name for DigitalOcean (alphanumeric, hyphens, underscores) |

## Notes

- The trait requires classes to have `$this->fs` (FilesystemService) and `$this->io` (IoService) properties available, typically inherited from BaseCommand
- All validators follow the `?string` return pattern: `null` indicates valid, string indicates error message
- The `promptPrivateKeyPath()` method allows empty input to trigger default key resolution, while `promptDeployKeyPairPath()` requires explicit path
- DSA keys are explicitly rejected with a specific error message rather than a generic format error
- FIDO2/U2F security key types are supported for public keys
- The trait is completely stateless - no instance variables or cached data
