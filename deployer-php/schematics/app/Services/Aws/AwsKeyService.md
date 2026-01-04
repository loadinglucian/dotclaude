# AwsKeyService

AWS EC2 key pair management service for importing and deleting SSH keys.

## Class Summary

| Property | Value |
|----------|-------|
| **Namespace** | `Deployer\Services\Aws` |
| **Extends** | `BaseAwsService` |
| **Type** | Service |
| **Final** | No |

## Dependencies

| Dependency | Type | Purpose |
|------------|------|---------|
| `FilesystemService` | Constructor injection | Read SSH public key file contents |
| `BaseAwsService` | Inheritance | AWS SDK and region management |
| `Aws\Sdk` | Runtime (via parent) | Create EC2 client |

## Public Methods

### `importKeyPair(string $publicKeyPath, string $keyName): string`

Imports a local SSH public key to AWS as an EC2 key pair.

**Parameters:**
- `$publicKeyPath` - Path to the SSH public key file
- `$keyName` - Name for the key pair in AWS

**Returns:** The key fingerprint from AWS

**Throws:** `\RuntimeException` on import failure

**Execution Flow:**
1. Read public key file via FilesystemService
2. Trim whitespace from key content
3. Create EC2 client via parent method
4. Call AWS `importKeyPair` API
5. Return fingerprint on success
6. Catch and wrap errors with cleaner messages

### `deleteKeyPair(string $keyName): void`

Deletes a key pair from AWS. Silently succeeds if key doesn't exist.

**Parameters:**
- `$keyName` - Key pair name to delete

**Throws:** `\RuntimeException` on deletion failure (non-404 errors)

**Execution Flow:**
1. Create EC2 client via parent method
2. Call AWS `deleteKeyPair` API
3. On error, check if "not found" message - return silently if so
4. Re-throw other errors wrapped in RuntimeException

## Dependents

| File | Usage |
|------|-------|
| `AwsService` | Exposes via `$aws->key` property |
| `KeyAddAwsCommand` | Calls `importKeyPair()` |
| `KeyDeleteAwsCommand` | Calls `deleteKeyPair()` |

## Important Behaviors

1. **SDK Requirement:** Must call `setSdk()` and `setRegion()` before use (done by AwsService.initialize())
2. **Idempotent Delete:** AWS `deleteKeyPair` doesn't error on missing keys, but error handling is defensive
3. **Duplicate Key Detection:** Checks for "already exists" in error messages for clearer user feedback
4. **Exception Wrapping:** All AWS exceptions are wrapped in `\RuntimeException` with original as `previous`

## Error Messages

| Condition | Message Pattern |
|-----------|-----------------|
| Duplicate key | `Key pair '{name}' already exists in this region` |
| Import failure | `Failed to import key pair: {aws_message}` |
| Delete failure | `Failed to delete key pair: {aws_message}` |
| SDK not set | `AWS SDK not configured. Call setSdk() first.` (from parent) |
| Region not set | `AWS region not configured. Call setRegion() first.` (from parent) |
