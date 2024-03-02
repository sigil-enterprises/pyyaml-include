"""
Include other YAML files in YAML
"""

import sys
from itertools import chain
from os import PathLike
from pathlib import Path
from typing import Callable, Optional, Type, Union

from urllib.parse import urlsplit, urlunsplit

import fsspec
import fsspec.core
import fsspec.spec
import yaml

from ._version import __version__, __version_tuple__, version, version_tuple

__all__ = ["YamlIncludeCtor", "version", "version_tuple"]


class YamlIncludeCtor:
    """The include constructor for PyYAML Loaders

    Use :func:`yaml.add_constructor` to register it on PyYAML's Loaders.

    Example:

        #. In Python source code, register it to a Loader class::

            import yaml

            from yamlinclude import YamlIncludeCtor

            yaml.add_constructor("!inc", YamlIncludeCtor(), yaml.Loader)

        #. In a YAML file, write ``!inc`` tags to include other YAML files. We can:

            * include file in local file system, absolute or relative

                .. code:: yaml

                    file: !inc /absolute/dir/of/foo/baz.yml

                .. code:: yaml

                    file: !inc ../../foo/baz.yml

            * include file from a website

                .. code:: yaml

                    file: !inc http://localhost:8080/foo/baz.yml

            * include file by wildcards

                .. code:: yaml

                    files: !inc foo/**/*.yml

        #. load the YAML in python::

            data = yaml.load(yaml_string, yaml.Loader)

           The variable ``data`` containers the parsed Python object(s) from including file(s)
    """

    def __init__(
        self,
        fs: Optional[fsspec.AbstractFileSystem] = None,
        base_dir: Union[str, PathLike, Callable[[], Union[str, PathLike]], None] = None,
        custom_loader: Optional[Callable] = None,
    ):
        """
        Args:
            fs:
                :mod:`fsspec` File-system object to parse path/url and open including files. `LocalFileSystem` by default.
            base_dir:
                Base directory to which search including YAML files in relative mode

            custom_loader:
                Custom loader/parser function called when a including file to be parsed.

                :Default: ``None`` - parse the file as ordinary YAML.

                If not ``None``, it shall be defined like::

                    def my_loader(urlpath, file, Loader, *args, **kwargs):
                        ...

                Args:

                    arg1 (str):
                        ``urlpath`` - url / path of the file.

                        Pass-in value of the parameter is:

                        * original url/path defined in YAML, if no wildcard in the including express.
                        * file name returned by :meth:`fsspec.spec.AbstractFileSystem.glob`, if wildcard in the including express.

                        Warning:
                            If YAML include express has both scheme and wildcard (eg: ``http://host/foo/*.yml``), pass-in value of the argument will be an empty string.

                    arg2 (Any):
                        ``file`` - What returned by :func:`fsspec.open` or the list member of :func:`fsspec.open_files`'s return value will be passed to the argument.

                        Type of the parameter is usually one of:

                        * Subclass of :class:`io.IOBase`
                        * Subclass of :class:`fsspec.spec.AbstractBufferedFile`

                        The type is **NOT** certain however, because different :mod:`fsspec` implementations ``open`` methods have variable return types.

                    arg3:
                        `Loader` - :mod:`yaml`'s Loader class

                    ...:
                        Other positional or named parameters in YAML including express

                Returns:
                    Any: What parsed
        """
        self._fs: fsspec.AbstractFileSystem = (
            fsspec.filesystem("file") if fs is None else fs
        )
        self._base_dir = base_dir
        self._custom_loader = custom_loader

    def __call__(self, loader, node: yaml.nodes.Node):
        if isinstance(node, yaml.nodes.ScalarNode):
            value = loader.construct_scalar(node)
            return self.load(type(loader), value)
        elif isinstance(node, yaml.nodes.SequenceNode):
            value = loader.construct_sequence(node)
            return self.load(type(loader), *value)
        elif isinstance(node, yaml.nodes.MappingNode):
            value = loader.construct_mapping(node)
            return self.load(type(loader), **value)
        else:  # pragma: no cover
            raise ValueError(f"PyYAML node {node!r} is not supported by {type(self)}")

    @staticmethod
    def _has_wildcards(s, wildcards="*?[]"):
        return any(c in s for c in wildcards)

    def _load_from_open_file(self, file, loader_type, path, *args, **kwargs):
        if self._custom_loader is None:
            return yaml.load(file, loader_type)
        return self._custom_loader(path, file, loader_type, *args, **kwargs)

    def load(self, loader_type: Type, urlpath: str, *args, **kwargs):
        """Once the constructor was added to PyYAML loader class,
        the loader class will invoke this function to include other YAML files when meet an including tag(eg: ``"!inc"``).

        Args:

            loader_type:
                Type of PyYAML's loader class

            urlpath:
                urlpath can be either absolute (like `/usr/src/Python-1.5/*.yml`) or relative (like `../../Tools/*/*.yml`), and can contain shell-style wildcards

                We support "**", "?" and "[..]". We do not support "^" for pattern negation.
                The `maxdepth` option is applied on the first "**" found in the path.

                Note:
                    If

                Warning:
                    Using the ``"**"`` pattern in large directory trees or remote files may consume an inordinate amount of time.

            kwargs:
                may have additional :mod:`fsspec` backend-specific options

        Returns:
            Data of included YAML file, pared to python object

        Warning:
            It's called by `PyYAML`, and do NOT call it yourself.
        """

        url_sr = urlsplit(urlpath)
        if self._base_dir is not None:
            if callable(self._base_dir):
                base_dir = Path(self._base_dir())
            else:
                base_dir = Path(self._base_dir)
            if url_sr.scheme:
                urlpath = urlunsplit(
                    chain(
                        url_sr[:2],
                        (base_dir.joinpath(url_sr[2]).as_posix(),),
                        url_sr[3:],
                    )
                )
            else:
                urlpath = base_dir.joinpath(urlpath).as_posix()

        # If protocol/scheme in path, we shall open it directly with fs's default open method
        if url_sr.scheme:
            if self._has_wildcards(urlpath):
                # if wildcards in path, return a Sequence/List
                result = []
                with fsspec.open_files(urlpath, *args, **kwargs) as ofs:
                    for of_ in ofs:
                        data = self._load_from_open_file(
                            of_, loader_type, "", *args, **kwargs
                        )
                        result.append(data)
                return result
            # else if no wildcard, returns a single object
            with fsspec.open(urlpath, *args, **kwargs) as of_:
                assert not isinstance(of_, list)
                result = self._load_from_open_file(
                    of_, loader_type, "", *args, **kwargs
                )
                return result

        # if no protocol / scheme in path, we shall use the `fs` object
        if self._has_wildcards(urlpath):
            urlpath = Path(urlpath).as_posix()
            # if wildcard in path, returns a List
            glob_params = open_params = None
            if args:
                if len(args) > 1:
                    glob_params, open_params = args[:2]
                elif len(args) == 1:
                    glob_params = args[0]
            if kwargs:
                glob_params = kwargs.get("glob")
                open_params = kwargs.get("open")

            if glob_params is None:
                glob_fn = lambda: self._fs.glob(urlpath)  # noqa: E731
            elif isinstance(glob_params, dict):
                # special for maxdepth, because PyYAML sometimes treat number as string for constructor's parameter
                if "maxdepth" in glob_params:
                    glob_params["maxdepth"] = int(glob_params["maxdepth"])
                glob_fn = lambda: self._fs.glob(urlpath, **glob_params)  # noqa: E731
            elif isinstance(glob_params, (list, set)):
                # special for maxdepth, because PyYAML sometimes treat number as string for constructor's parameter
                glob_params = list(glob_params)
                if glob_params:
                    glob_params[0] = int(glob_params[0])
                glob_fn = lambda: self._fs.glob(urlpath, *glob_params)  # noqa: E731
            else:
                # special for maxdepth, because PyYAML sometimes treat number as string for constructor's parameter
                maxdepth = int(glob_params)
                glob_fn = lambda: self._fs.glob(urlpath, maxdepth)  # noqa: E731

            if open_params is None:
                open_fn = lambda x: self._fs.open(x)  # noqa: E731
            elif isinstance(open_params, dict):
                open_fn = lambda x: self._fs.open(x, **open_params)  # noqa: E731
            elif isinstance(open_params, (list, set)):
                open_fn = lambda x: self._fs.open(x, *open_params)  # noqa: E731
            else:
                open_fn = lambda x: self._fs.open(x, open_params)  # noqa: E731

            result = []
            for file in glob_fn():
                with open_fn(file) as of_:
                    data = self._load_from_open_file(
                        of_, loader_type, file, *args, **kwargs
                    )
                    result.append(data)
            return result

        # else if no wildcards, return a single object
        with self._fs.open(urlpath, *args, **kwargs) as of_:
            result = self._load_from_open_file(
                of_, loader_type, urlpath, *args, **kwargs
            )
            return result
