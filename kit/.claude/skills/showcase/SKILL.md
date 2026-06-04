---
name: showcase
description: Build an example-block post that demonstrates a Gutenberg block's core variations — one section per variation, each labeled with a standard-content heading. A QA/demonstration page to verify every layout and setting renders. Triggered by /showcase [block], "make an example block for X", "show all variations of X", "demo this block".
---

# Showcase — one example-block post that exercises a block's core variations

Takes one cool-fse Gutenberg block and builds (or refreshes) a single **`example-block`**
post that stacks the block's **core variations** — every layout option, view, and the
toggles that change *what the block is*, not the per-pixel style knobs. Each variation is
preceded by a **`standard-content`** block whose `<h2>` describes that variation.

The result is a living QA page: open it and you can see at a glance that every setting of
the block renders correctly. This is a standalone utility — not part of the
ponder → forge → temper → seal chain. Run it anytime, especially after building or porting a
block, to verify it visually.

## Invocation

```
/showcase                 # "which block?"
/showcase hero            # showcase the hero block
/showcase content-carousel
```

## What "core variation" means

Demonstrate the things that make this block *this block*. **Skip** the universal style
chrome.

| Demonstrate (core) | Skip (chrome) |
|---|---|
| Each `select` that changes layout/structure (e.g. `layout`, `carousel_side`, `display_option`) | Padding / margin / wrapper-width fields (the `styles` clone) |
| Each major view/mode (e.g. slides vs static, image vs video) | Background color / text color / link color |
| Structural `true_false` toggles (autoplay, border, peek, overlap) | Responsive-display, animation, date-behavior |
| Meaningful edge cases (1 slide vs many; empty optional field; dark vs light control mode) | Anchor / additional CSS class |

Aim for a **representative matrix, not a combinatorial explosion** — one section per
distinct layout/view, plus a few sections that toggle the block-defining options on top of
the most common layout. ~3–8 sections is typical. If a block is trivial (no layout/mode
fields), one or two sections is fine.

## Workflow

### 1. Resolve the block

From the arg (or ask). Find its directory — child theme wins over parent:
- `{{CHILD_THEME_DIR}}/blocks/gutenberg/<block>/`
- else `cool-fse/blocks/gutenberg/<block>/`

Read the block's **`<block>.php`** (how fields drive rendering) and its **ACF JSON group**
in `{{CHILD_THEME_DIR}}/acf-json/` (or `cool-fse/acf-json/`). Identify:
- the **variation-driving fields** (selects, structural toggles) — these define your sections
- the **required content fields** to make it render (content, slides, gallery, image, etc.)
- each field's **key** (`"key": "field_…"`) and **name** — you need both to serialize

### 2. Gather real media

Most blocks need images. Pull valid attachment IDs from the library so slides aren't empty:

```bash
wp post list --post_type=attachment --posts_per_page=12 --field=ID
```

(See **Running wp-cli on Local** below if `wp` errors with a DB connection failure.)

### 3. Author the variations

Write a small builder (Python is easiest for the escaping). For each variation produce:
1. a **`standard-content` label** — `<h2>` = a short descriptor of the variation, **XXL top
   padding (64px) + medium bottom padding (16px)** (per the house rule for these labels)
2. the **block instance** with that variation's field values

Then join all sections into one post body. Serialize ACF blocks in the
WordPress block-comment format (see **Serializing an ACF block** below).

### 4. Create or update the example-block post (idempotent)

One `example-block` post per block, titled after the block (e.g. "Hero", "Content
Carousel"). If one already exists with that title, **update it** — don't pile up duplicates.

```bash
# find existing
wp post list --post_type=example-block --field=ID --post_status=any \
  --title="Hero"        # if your wp-cli lacks --title, list all and match titles yourself
# create
ID=$(wp post create --post_type=example-block --post_status=publish --post_title="Hero" --porcelain)
# set body (from a file to avoid shell-escaping the markup)
wp post update "$ID" --post_content="$(cat /tmp/showcase-body.html)"
```

### 5. Verify

- **No PHP errors / every section present** — fetch the rendered page (see next step) and
  confirm each block class + the labels are there, with no `Fatal error` / `Warning`.
- `example-block` posts are **admin-only** (`exclude_from_search`, not anon-public). The
  front-end URL **404s for logged-out requests** — that's expected, not a bug. Verify by
  either:
  - a logged-in browser session (Playwright: log in at `{{LOCAL_URL}}wp-login.php` with the
    creds in `.claude/credentials.md`, then visit the permalink), or
  - `wp post get <ID> --field=content` to confirm the markup is intact.

### 6. Hand off

Give the user the permalink and tell them they must be logged into wp-admin to view it:

> Showcase ready: **{{LOCAL_URL}}example-blocks/<slug>/** (log into wp-admin to view).
> N sections: <list the variation descriptors>.

---

## Mechanics

### Running wp-cli on Local

Local by Flywheel runs MySQL on a socket, so a global `wp` often fails with *"Error
establishing a database connection."* Point PHP at Local's socket:

```bash
SOCK=$(ls ~/Library/Application\ Support/Local/run/*/mysql/mysqld.sock 2>/dev/null | head -1)
WPROOT="<absolute path to app/public>"      # the WordPress root, above wp-content/
wp() { php -d mysqli.default_socket="$SOCK" -d pdo_mysql.default_socket="$SOCK" \
        "$(command -v wp)" --path="$WPROOT" "$@"; }
wp option get siteurl    # should print {{LOCAL_URL}}
```

Define that wrapper once per session, then use `wp …` normally.

### Serializing an ACF block

An ACF block in post content is an HTML comment carrying JSON:

```
<!-- wp:acf/<block-name> {"name":"acf/<block-name>","data":{ …flat data… },"mode":"preview"} /-->
```

The `data` object is **flat**: every field is `"<name>": value` plus a sibling
`"_<name>": "<field_key>"`. Repeater rows flatten with an index
(`slides_0_image`, `_slides_0_image`), nested groups with the path
(`style_group_padding_top`). Get each `<field_key>` from the block's ACF JSON.

**Escaping (critical):** inside the JSON string values, escape `<`→`<`, `>`→`>`,
`"`→`"`, `&`→`&`, or the comment/JSON breaks. Build the JSON with a real
serializer, then post-process — don't hand-type escapes. Python pattern:

```python
import json
def wpblock(name, data):                       # name like "acf/hero"
    s = json.dumps({"name":name,"data":data,"mode":"preview"},
                   separators=(',',':'), ensure_ascii=False)
    return "<!-- wp:%s %s /-->" % (name,
        s.replace('\\"','\\u0022').replace('<','\\u003c').replace('>','\\u003e').replace('&','\\u0026'))
```

Always round-trip-validate before writing: strip the `<!-- wp:… ` / ` /-->` wrapper and
`json.loads` the middle. A single unescaped quote silently corrupts the block.

### The standard-content label

The label before each variation is a `standard-content` block with an `<h2>` and the house
padding (**XXL top = 64px, medium bottom = 16px**). The padding rides the shared cool-fse
`styles` group, whose field keys are stable across cool-fse projects:

```python
def label(text, pad_top="64px", pad_bottom="16px"):
    return wpblock("acf/standard-content", {
      "content": '<h2 style="text-align: center;">%s</h2>' % text,
      "_content": "field_66b42dda5f1c2",                 # standard-content "content" key
      "style_group_padding_top":    pad_top,    "_style_group_padding_top":    "field_66b434d012905",
      "style_group_padding_right":  "16px",     "_style_group_padding_right":  "field_66b434d812906",
      "style_group_padding_bottom": pad_bottom, "_style_group_padding_bottom": "field_66b434e312907",
      "style_group_padding_left":   "16px",     "_style_group_padding_left":   "field_66b434e912908",
      "style_group_padding": "",                "_style_group_padding":        "field_66b434b2af9d1",
      "style_group": "",                        "_style_group":                "field_66b4438bfd207",
      "styles": "",                             "_styles":                     "field_2cd8266024037",
    })
```

Confirm the `content` key against the standard-content ACF group, and the `style_group_*`
keys against any existing block pattern in the project (they're the shared style fields —
identical across cool-fse blocks). The cool-fse **spacing scale**: `none`0 · `x-small`4 ·
`small`8 · `medium-small`12 · **`medium`16** · `medium-large`24 · `large`32 · `x-large`48 ·
**`xx-large`64** · `huge`120 · `massive`240 (px).

### Field keys from the ACF JSON

To resolve `name → key`, read the group JSON and walk `fields[]` (and `sub_fields` /
`layouts.*.sub_fields` for repeaters/flex):

```bash
python3 - "$ACF_JSON" <<'PY'
import json,sys
def walk(fs,pre=""):
  for f in fs:
    if f.get('name'): print(f"{pre}{f['name']:30} {f['key']}  ({f['type']})")
    walk(f.get('sub_fields',[]),pre+"  ")
    for L in f.get('layouts',{}).values(): walk(L.get('sub_fields',[]),pre+"  ")
walk(json.load(open(sys.argv[1]))['fields'])
PY
```

## Rules

- **Theme blocks only — never core WordPress blocks.** Every block in the post is a cool-fse
  `acf/*` block. Do **not** use `wp:heading`, `wp:paragraph`, `wp:group`, `wp:spacer`, or any
  other core block — not for the labels, not for spacing, not for anything. **Any headline or
  copy is a `standard-content` block** with the HTML (e.g. `<h2>…</h2>`) inside its `content`
  field. This holds everywhere in cool-fse, not just here: text content is always a theme
  block, never a core block.
- **One post per block**, idempotent by title — update, don't duplicate.
- **Labels describe the variation** in plain words ("Full-Bleed · Carousel Right · Autoplay"),
  not field keys.
- **Core variations only** — layouts, views, structural toggles, key edge cases. Don't make a
  section per padding value.
- **Use real media IDs** from the library so every section renders with content.
- **Don't invent fields.** Every field name/key must exist in the block's ACF group. If a
  field you need isn't there, stop and tell the user.
- **example-block posts are admin-only** — a logged-out 404 is expected; verify logged-in.
- This skill **creates content, never commits** and never edits block source.
