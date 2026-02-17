---
name: wp-dev
description: WordPress plugin and theme development helper. Use when working on WordPress projects to follow WP coding standards and hook-based architecture.
---

# WordPress Development Helper

Assists with WordPress plugin and theme development following WordPress coding standards.

## Context Detection

Before generating code, check the project's CLAUDE.md and determine:

1. **Plugin or theme?** Check for `style.css` (theme) or main plugin file with `Plugin Name:` header
2. **Child theme?** Check for `Template:` in `style.css`
3. **Dependencies**: Check `composer.json` for PHP deps, look for vendored JS
4. **Integrations**: MemberPress, ACF, WooCommerce, etc.

## Coding Standards

Follow WordPress Coding Standards:

- **Naming**: `snake_case` for functions/variables, `Upper_Snake_Case` for classes
- **Hooks**: All functionality registered via `add_action()` / `add_filter()`
- **Escaping**: Always escape output — `esc_html()`, `esc_attr()`, `esc_url()`, `wp_kses_post()`
- **Sanitizing**: Always sanitize input — `sanitize_text_field()`, `absint()`, `wp_unslash()`
- **Nonces**: Use `wp_nonce_field()` / `wp_verify_nonce()` for form submissions
- **Database**: Use `$wpdb->prepare()` for all queries, never interpolate directly
- **Enqueuing**: Use `wp_enqueue_script()` / `wp_enqueue_style()` with proper dependencies and versions

## Plugin Patterns

### Main Plugin File
```php
/**
 * Plugin Name: My Plugin
 * Description: Brief description
 * Version: 1.0.0
 */

if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

define( 'MY_PLUGIN_PATH', plugin_dir_path( __FILE__ ) );
define( 'MY_PLUGIN_URL', plugin_dir_url( __FILE__ ) );
```

### Custom Post Types
```php
add_action( 'init', 'my_register_post_type' );
function my_register_post_type() {
    register_post_type( 'my_cpt', [
        'labels'       => [...],
        'public'       => true,
        'has_archive'  => true,
        'supports'     => [ 'title', 'editor', 'thumbnail' ],
        'show_in_rest' => true,
    ] );
}
```

### Shortcodes
```php
add_shortcode( 'my_shortcode', 'my_shortcode_handler' );
function my_shortcode_handler( $atts ) {
    $atts = shortcode_atts( [ 'id' => 0 ], $atts );
    ob_start();
    // template output
    return ob_get_clean();
}
```

## Theme Patterns

### Child Theme functions.php
```php
add_action( 'wp_enqueue_scripts', 'child_enqueue_styles' );
function child_enqueue_styles() {
    wp_enqueue_style( 'parent-style', get_template_directory_uri() . '/style.css' );
    wp_enqueue_style( 'child-style', get_stylesheet_uri(), [ 'parent-style' ] );
}
```

## Key Rules

- Never use `echo` without escaping in templates
- Never write raw SQL without `$wpdb->prepare()`
- jQuery-based JS unless the project explicitly uses modern tooling
- Check if the project has a build step before assuming CSS preprocessors exist
- WP Engine deployment: no build step on server, commit compiled assets
- When generating Redmine markdown, use Textile formatting (inherited from global CLAUDE.md)
