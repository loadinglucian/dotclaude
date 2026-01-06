---
paths: app/**/*.php, routes/**/*.php, database/**/*.php, config/**/*.php, bootstrap/**/*.php
---

# Laravel Rules

<important>

- **Artisan commands:** Use `php artisan make:` with `--no-interaction` for all file generation
- **Eloquent first:** Prefer `Model::query()` over `DB::` facade—leverage ORM, not raw queries
- **Form Requests:** Always create Form Request classes for validation, never inline in controllers
- **Config access:** Use `config('key')` everywhere—`env()` only allowed inside config files
- **Search docs first:** Use `search-docs` tool before making code changes to ensure correct approach

</important>

<examples>

  <example name="eloquent-vs-db" type="correct">
```php
// Eloquent with eager loading (prevents N+1)
$users = User::query()
    ->with(['posts', 'comments'])
    ->where('active', true)
    ->get();
```
  </example>

  <example name="eloquent-vs-db" type="wrong">
```php
// Raw DB facade - bypasses ORM benefits
$users = DB::table('users')
    ->join('posts', 'users.id', '=', 'posts.user_id')
    ->where('active', true)
    ->get();
```
  </example>

  <example name="form-request" type="correct">
```php
// Controller using Form Request
public function store(StoreUserRequest $request): JsonResponse
{
    $user = User::create($request->validated());
    return response()->json($user, 201);
}

// Form Request class
class StoreUserRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users'],
        ];
    }
}
```
  </example>

  <example name="form-request" type="wrong">
```php
// Inline validation in controller
public function store(Request $request): JsonResponse
{
    $validated = $request->validate([
        'name' => 'required|string|max:255',
        'email' => 'required|email|unique:users',
    ]);
    // ...
}
```
  </example>

  <example name="config-access" type="correct">
```php
// In application code
$appName = config('app.name');
$apiKey = config('services.stripe.key');
```
  </example>

  <example name="config-access" type="wrong">
```php
// env() outside config files
$appName = env('APP_NAME');
$apiKey = env('STRIPE_KEY');
```
  </example>

  <example name="route-naming" type="correct">
```php
// Named routes
Route::get('/users/{user}', [UserController::class, 'show'])->name('users.show');

// Using named routes
return redirect()->route('users.show', $user);
$url = route('users.show', ['user' => $user->id]);
```
  </example>

  <example name="model-casts" type="correct">
```php
// Laravel 11+ casts method
class User extends Model
{
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'settings' => 'array',
            'is_admin' => 'boolean',
        ];
    }
}
```
  </example>

  <example name="search-docs-usage">
```
// Use multiple broad queries
search-docs queries: ['eloquent relationships', 'eager loading', 'N+1']

// Do NOT include package names
search-docs query: 'rate limiting'  // correct
search-docs query: 'laravel rate limiting'  // wrong - redundant
```
  </example>

</examples>

<context>

## Laravel 12 Structure

Laravel 11+ uses a streamlined file structure:

| Old Location | New Location |
|--------------|--------------|
| `app/Http/Middleware/` | No files—middleware configured in `bootstrap/app.php` |
| `app/Console/Kernel.php` | Removed—use `bootstrap/app.php` or `routes/console.php` |
| Service Providers | Registered in `bootstrap/providers.php` |

**Commands auto-register:** Files in `app/Console/Commands/` are automatically available.

## Bootstrap Files

- `bootstrap/app.php` - Register middleware, exceptions, routing files
- `bootstrap/providers.php` - Application service providers

## Database Migrations

When modifying a column, include ALL previous attributes—missing ones will be dropped:

```php
// Must preserve ALL attributes when modifying
$table->string('name', 100)->nullable()->change();
```

</context>

<instructions>

## Artisan Commands

- Use `php artisan make:` for controllers, models, migrations, etc.
- Always pass `--no-interaction` to ensure non-interactive execution
- Use `list-artisan-commands` tool to verify available options

```bash
php artisan make:model Post --migration --factory --no-interaction
php artisan make:controller PostController --resource --no-interaction
php artisan make:request StorePostRequest --no-interaction
```

## Database & Eloquent

- Use proper relationship methods with return type hints
- Prevent N+1 with eager loading: `->with(['relation'])`
- Use `Model::query()` for fluent building, not `DB::`
- Native eager load limits (Laravel 11+): `$query->latest()->limit(10)`

## Controllers & Validation

- Create Form Request classes for all validation
- Check sibling Form Requests for array vs string rule format
- Include custom error messages when helpful

## Queues & Jobs

- Use `ShouldQueue` interface for time-consuming operations
- Implement proper job middleware and rate limiting

## Authentication & Authorization

- Use Laravel's built-in features: gates, policies, Sanctum
- Define policies for model authorization

## URL Generation

- Prefer named routes with `route()` function
- Share URLs with `get-absolute-url` tool for correct scheme/domain/port

## Laravel Boost MCP Tools

### Documentation Search (Critical)
Use `search-docs` BEFORE making code changes:

```
queries: ['topic1', 'topic2']  // Multiple broad queries
packages: ['laravel', 'livewire']  // Optional package filter
```

Search syntax:
- Simple: `authentication` (auto-stems to 'auth')
- AND logic: `rate limit` (both words required)
- Exact phrase: `"infinite scroll"`
- Mixed: `middleware "rate limit"`

### Debugging Tools
- `tinker` - Execute PHP to debug or query Eloquent
- `database-query` - Read-only database queries
- `browser-logs` - Read browser errors (recent logs only)
- `last-error` - Get last application error

### Other Tools
- `list-artisan-commands` - Verify Artisan command options
- `get-absolute-url` - Get correct URL with scheme/domain/port
- `application-info` - Get app configuration details

## Frontend Bundling

If Vite manifest errors occur or frontend changes don't appear:

```bash
bun run build    # Production build
bun run dev      # Development server
composer run dev # Alternative dev command
```

</instructions>

## Standards

- Use Eloquent relationships and eager loading to prevent N+1
- Create Form Request classes for all validation logic
- Use named routes exclusively for URL generation
- Access configuration via `config()` helper only
- Search documentation before implementing new features
- Use `casts()` method for model attribute casting (Laravel 11+)
- Pass `--no-interaction` to all Artisan commands

## Constraints

- Never use `env()` outside of config files
- Never use `DB::` facade when Eloquent suffices
- Never inline validation in controllers
- Never create middleware files in `app/Http/Middleware/`
- Never create `app/Console/Kernel.php`
- Never modify columns without preserving all existing attributes
- Never skip `search-docs` for unfamiliar Laravel features
