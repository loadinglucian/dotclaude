---
paths: tests/**/*.php
---

# PEST Testing RULES

## Context

Tests verify behavior using Pest PHP `it()` syntax. AAA pattern. Business logic over type checking.

**Philosophy:** "A test that never fails is not a test, it's a lie."

**Coverage:** 70%+ minimum.

**Commands:**

```bash
composer pest                 # Full suite with coverage (parallel)
vendor/bin/pest $TEST_FILE    # Specific file
```

## Examples

### Example: File Structure

```php
<?php

declare(strict_types=1);

//
// {Feature} tests
// ----

it('does something specific', function () {
    // ARRANGE
    $service = new Service(mock(Dependency::class));

    // ACT
    $result = $service->action();

    // ASSERT
    expect($result)->toBe('expected');
});

it('throws when invalid input', function () {
    $service = new Service();

    // ACT & ASSERT
    expect(fn () => $service->action('invalid'))
        ->toThrow(InvalidArgumentException::class, 'Expected message');
});
```

### Example: AAA Pattern

```php
it('calculates total with tax', function () {
    // ARRANGE
    $calculator = new PriceCalculator(taxRate: 0.1);
    $items = [['price' => 100], ['price' => 50]];

    // ACT
    $total = $calculator->calculateTotal($items);

    // ASSERT
    expect($total)->toBe(165.0);
});
```

### Example: Exception Test

```php
it('throws on negative price', function () {
    $calculator = new PriceCalculator();

    // ACT & ASSERT
    expect(fn () => $calculator->calculateTotal([['price' => -10]]))
        ->toThrow(InvalidArgumentException::class);
});
```

### Example: Naming (Correct)

```php
it('returns empty array when no servers configured')
it('throws when SSH connection fails')
it('creates deploy key with correct permissions')
```

### Example: Naming (Wrong)

```php
it('test1')
it('works')
it('should return correct value')
```

### Example: Unit Test DI

```php
it('parses config correctly', function () {
    $mockFs = mock(FilesystemInterface::class);
    $mockFs->shouldReceive('read')->with('/path')->andReturn('content');

    $service = new ConfigService($mockFs);
    $result = $service->parse('/path');

    expect($result)->toBe(['key' => 'value']);
});
```

### Example: Command Test DI

```php
it('adds server successfully', function () {
    $mockSSH = mock(SSHService::class);
    $mockSSH->shouldReceive('connect')->andReturn(true);

    $container = mockCommandContainer(ssh: $mockSSH);
    $command = $container->build(ServerAddCommand::class);

    // Test command execution
});
```

### Example: Datasets

```php
it('validates server names', function (string $name, bool $valid) {
    $validator = new ServerValidator();

    expect($validator->isValidName($name))->toBe($valid);
})->with([
    'valid simple' => ['web-server', true],
    'valid with numbers' => ['web1', true],
    'invalid spaces' => ['web server', false],
    'invalid special chars' => ['web@server', false],
    'empty string' => ['', false],
]);
```

### Example: Assertion Chaining (Correct)

```php
expect($server)
    ->name->toBe('web1')
    ->and($server)
    ->host->toBe('192.168.1.1')
    ->and($server)
    ->port->toBe(22);
```

### Example: Assertion Chaining (Wrong)

```php
expect($server->name)->toBe('web1');
expect($server->host)->toBe('192.168.1.1');
expect($server->port)->toBe(22);
```

### Example: Mocking

```php
it('calls external service', function () {
    $mock = mock(ExternalService::class);
    $mock->shouldReceive('fetch')
        ->once()
        ->with('param')
        ->andReturn(['data']);

    $service = new MyService($mock);
    $result = $service->process();

    expect($result)->toBe('processed');
});
```

### Example: Arch Test

```php
arch('commands extend BaseCommand', function () {
    expect('Deployer\\Console\\')
        ->classes()
        ->toHaveSuffix('Command')
        ->toExtend(BaseCommand::class);
});

arch('services are final', function () {
    expect('Deployer\\Service\\')
        ->classes()
        ->toBeFinal();
});
```

## Instructions

### AAA Pattern

- Every test follows Arrange-Act-Assert
- Use `// ARRANGE`, `// ACT`, `// ASSERT` comments
- Exception tests: use `// ACT & ASSERT` when act triggers assertion

### Test Naming

- Use descriptive `it()` statements that read as sentences
- Describe behavior, not implementation

### Dependency Injection

DI rules apply to PRODUCTION code, not tests.

- **Unit tests:** Manual instantiation with mocks
- **Command tests:** Container with mock bindings via `mockCommandContainer()`

### Minimalism

**Target:** Test files under 1.8x source code size.

- Test core business logic only
- Use datasets for multiple scenarios: `->with([])`
- Eliminate overlap: no two tests covering same functionality
- Consolidate assertions: `expect($x)->toBe(1)->and($y)->toBe(2)`
- Mock external dependencies only
- **Don't consolidate:** Different public methods, exception vs normal flow, distinct business logic

### Forbidden Patterns

```php
// Type-only checks (prove nothing about behavior)
expect($x)->toBeInstanceOf(Class::class);
expect($x)->toBeArray();
expect($x)->not->toBeNull();

// Literally meaningless
expect(true)->toBeTrue();

// Time-dependent (test logic, not time)
sleep(1);
usleep(1000);
```

### Required Patterns

```php
// Verify actual values
expect($config->getValue('host'))->toBe('example.com');

// Verify mock interactions
$mock->shouldReceive('method')->with('param')->andReturn('result');

// Polling/timeout: use zero intervals
$service->waitForReady('id', timeout: 10, pollInterval: 0);
```

### Mock Patterns

```php
$mock->shouldReceive('method')->andReturn('value');
$mock->shouldReceive('method')->andReturn('first', 'second', 'third');
$mock->shouldReceive('method')->andThrow(new RuntimeException('error'));
$mock->shouldReceive('method')->once();
$mock->shouldReceive('method')->twice();
$mock->shouldReceive('method')->times(3);
$mock->shouldReceive('method')->never();
$mock->shouldReceive('method')->with('exact');
$mock->shouldReceive('method')->with(Mockery::any());
$mock->shouldReceive('method')->with(Mockery::type('string'));
```

### Test Types

| Layer             | Test Type   |
| ----------------- | ----------- |
| CLI Commands      | Integration |
| Business Services | Unit        |
| Utilities/Helpers | Unit        |

### Organization

- Use section comments: `// {Section} tests // ----`
- File naming: `tests/Unit/ServiceNameTest.php` or `tests/Integration/FeatureTest.php`
- Mirror source structure where practical

### Static Analysis

PHPStan applies to PRODUCTION code, not tests. Focus on functionality over type compliance.

## Quality Gate

After writing or editing tests:

```
**AAA Pattern:** PASS | FAIL
**Descriptive Names:** PASS | FAIL
**No Forbidden Assertions:** PASS | FAIL
**Datasets for Scenarios:** PASS | FAIL | N/A
**Value Assertions (not type-only):** PASS | FAIL
**Mock Interactions Verified:** PASS | FAIL | N/A
**No Test Overlap:** PASS | FAIL

**Proceeding with:** [run tests] | **Blocked by:** [issue to fix]
```
