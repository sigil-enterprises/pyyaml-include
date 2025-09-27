from pathlib import Path

import yaml
import yaml_include


def test_include_directive_inlines_yaml(tmp_path: Path):
    """
    Tests that the !include directive correctly inlines content from another YAML file.
    """

    yaml.add_constructor("!include", yaml_include.Constructor(base_dir='.'))

    with open("tests/fixtures/outer.yaml") as fp:
      loaded_data = yaml.full_load(fp)

    # 4. Assert that the content was correctly inlined
    expected_data = {
      "main_key": "This is from the main file.",
      "data": {
        "message": "Hello from the included file!",
        "value": 123,
        "obj": {
          "nested_value": 456,
        },
        "contextual": True,
      },
      "value": 123,
      "nested_value": 456,
      "importable": True,
    }
    assert loaded_data == expected_data