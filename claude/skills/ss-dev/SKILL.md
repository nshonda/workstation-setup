---
name: ss-dev
description: SilverStripe development helper for SS3, SS4, and SS5 projects. Use when working on any SilverStripe CMS project to generate code following correct patterns for that version.
---

# SilverStripe Development Helper

Assists with SilverStripe CMS development across versions 3, 4, and 5.

## Version Detection

Before generating any code, detect the SilverStripe version:

1. Check `composer.json` for `silverstripe/framework` version
2. Check for version indicators:
   - **SS3**: `framework/sake`, `mysite/` directory, no namespaces, `_config.php` as primary config
   - **SS4**: `vendor/silverstripe/`, `app/` directory, PSR-4 namespaces, `_config/*.yml`
   - **SS5**: Same as SS4 but `silverstripe/framework` ^5, `public/` web root, stricter typing

## Code Generation Patterns

### Page Types

**SS3:**
```php
class MyPage extends Page {
    private static $db = ['FieldName' => 'Varchar(255)'];
    private static $has_one = ['Image' => 'Image'];
}
class MyPage_Controller extends Page_Controller {}
```

**SS4/SS5:**
```php
namespace App\Pages;

use Page;
use SilverStripe\Assets\Image;

class MyPage extends Page {
    private static string $table_name = 'MyPage';
    private static array $db = ['FieldName' => 'Varchar(255)'];
    private static array $has_one = ['Image' => Image::class];
}
```

### DataExtensions

Always prefer extensions over subclasses. Apply via YAML config, not PHP.

**SS3:**
```php
class MyExtension extends DataExtension {
    private static $db = ['NewField' => 'Boolean'];
}
```

**SS4/SS5:**
```php
namespace App\Extensions;

use SilverStripe\ORM\DataExtension;

class MyExtension extends DataExtension {
    private static array $db = ['NewField' => 'Boolean'];
}
```

### After Schema Changes

Always remind to rebuild:
- **SS3**: `framework/sake dev/build "flush=1"` or `/dev/build?flush=1`
- **SS4/SS5**: `vendor/bin/sake dev/build flush=1` or `/dev/build?flush=1`

## Project-Specific Context

Read the project's CLAUDE.md for:
- Which SS version this project uses
- Theme structure and naming
- Custom module patterns
- Multi-tenant/multi-domain setup (especially ss3 project)
- Extension registration patterns

## Key Rules

- Use `private static` for configuration properties (not `public` or `protected`)
- Use `$table_name` in SS4/SS5 to avoid table name collisions
- Templates use `.ss` extension with `$Variable` and `<% if %>` syntax
- CMS fields: override `getCMSFields()`, use `FieldList` composition
- Always check if the project uses `translatable` or `fluent` for i18n before adding content fields
