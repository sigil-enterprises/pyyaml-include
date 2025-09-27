# Pyyaml Include

## Project Overview

**PyYAML-Include** is a powerful extension for the PyYAML library that allows you to include external YAML files within your YAML documents using a simple `!include` tag. This functionality helps in organizing complex configurations, reusing common snippets, and keeping your YAML files modular and maintainable.

Built on top of `fsspec`, it supports including files from various sources, including the local filesystem, remote URLs (HTTP, S3, etc.), and even from within Python packages.

## Key Features

- **Flexible Include Syntax**: Use `!include` for including files.
- **Multiple Sources**: Include files from the local filesystem, HTTP, S3, and any other filesystem supported by `fsspec`.
- **Wildcard Support**: Include multiple files at once using shell-like wildcards (`*`, `**`, `?`).
- **Deep-linking**: Extract and embed only a specific part of another YAML file.
- **Relative Includes**: Include files relative to the current file's location.
- **Package-Relative Includes**: Include files from installed Python packages.
- **Lazy Loading**: Defer the loading of included files until they are explicitly processed.
- **YAML Dumping**: `!include` tags are preserved when dumping the YAML back to a string or file.
- **Customizable**: Pass specific parameters for file opening (e.g., `compression`) or globbing (e.g., `maxdepth`).

## Getting Started

### Installation

```bash
pip install pyyaml-include
```

### Basic Usage

Let's say you have a main configuration file that needs to pull in database settings from another file.

**`db.yml`**
```yaml
host: localhost
port: 5432
user: myuser
```

**`config.yml`**
```yaml
app_name: My Awesome App
database: !include db.yml
```

Now, you can load `config.yml` in Python:

```python
import yaml
from yaml_include import Constructor

# Add the !include constructor to the PyYAML loader
yaml.add_constructor("!include", Constructor())

with open("config.yml") as f:
    config = yaml.full_load(f)

print(config)
```

**Output:**
```python
{
    'app_name': 'My Awesome App',
    'database': {
        'host': 'localhost',
        'port': 5432,
        'user': 'myuser'
    }
}
```

## Documentation

### Advanced Usage

#### Including from a URL

```yaml
config: !include https://example.com/path/to/remote_config.yml
```

#### Using Wildcards

You can include a list of YAML files. This is useful for things like loading a set of plugins or configurations.

**`services/service1.yml`**
```yaml
name: service1
port: 8001
```

**`services/service2.yml`**
```yaml
name: service2
port: 8002
```

**`config.yml`**
```yaml
services: !include services/*.yml
```

This will result in:
```python
{
    'services': [
        {'name': 'service1', 'port': 8001},
        {'name': 'service2', 'port': 8002'}
    ]
}
```

#### Flattening Included Lists

If each included file contains a list, you can flatten them into a single list.

**`list1.yml`**: `[1, 2, 3]`
**`list2.yml`**: `[4, 5, 6]`

```yaml
# Using the mapping syntax for !include
items: !include {urlpath: list*.yml, flatten: true}
```

Result: `{'items': [1, 2, 3, 4, 5, 6]}`

#### Including a Part of a File

You can include a specific key from another YAML file using a colon (`:`) followed by a dot-separated path.

**`settings.yml`**
```yaml
app:
  name: My App
  version: 1.0
db:
  host: db.example.com
```

**`config.yml`**
```yaml
database_host: !include settings.yml:db.host
```

Result: `{'database_host': 'db.example.com'}`


#### Including a file from a python module

You can include yaml file stored in a python module by using the `@` characted before the module name, then navigate as per module structure. Recomendation is to store all yaml of a module in a `/etc` folder inside the module.

**`python_module/etc/settings.yml`**
```yaml
app:
  name: My App
  version: 1.0
db:
  host: db.example.com
```

**`config.yml`**
```yaml
!include "@python_module/etc/settings.yml"
```

Result: `{'database_host': 'db.example.com'}`


#### Relative Includes

When dealing with nested includes, you can use `@/` to specify a path relative to the current file being processed.

**`base.yml`**
```yaml
common: !include common/values.yml
```

**`common/values.yml`**
```yaml
# This will look for 'details.yml' in the 'common' directory
details: !include "@/details.yml"
```

To make this work, you need to set the `base_dir` in the `Constructor`.

```python
import yaml
from yaml_include import Constructor

yaml.add_constructor("!include", Constructor(base_dir='.'))

with open("base.yml") as f:
    config = yaml.full_load(f)
```

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for bugs, feature requests, or questions.

## License

This project is [Private and Confidential](LICENSE).
