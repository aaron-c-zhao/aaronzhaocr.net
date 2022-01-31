---
layout: post
tags: ["Python", "Tutorial", "underTheHood"]
title:  "No more ModuleNotFound: how Python import works"
date:   2022-01-05 20:37:56 +0100
categories: Python
---
***
**TOC**

* TOC
{:toc}

***
Newcomers to the Python world like me will inevitably encounter this error `ModuleNotFound`. After realizing that it won't go anywhere messing around while hoping it magically fixes itself. I try to take a peek under the hood and find the answer to some of my questions. 

## What are you importing with `import`?
In Python, everything is an object. So with `import`, ultimately, you are importing a module object which will be put into the global scope of your current module as an attribute. Within the imported module object, sit the class and function objects you can access with the *dot* syntax, e.g. `foo.bar.hello_world` . And this odd name with dots is something called the [fully qualified name](https://docs.python.org/3/glossary.html#term-qualified-name)(FQN) of the functions or classes. In this way, the other module severs as an individual 'namespace' and prevents name collisions between modules. 

For example, if we have the Python files structured like this:
```bash
.
└── src
    ├── bar.py
    ├── dummy_submodule
    │   └── dummy.py
    └── foo.py
```
We implement a hello_world function in bar, and import bar from foo.
```python
# bar.py
def hello_world():
    print("hello world")

# foo.py
import bar
breakpoint()
```

With the breakpoint set in foo we can interact and inspect the stack content of the program.

```bash
-> breakpoint()
(Pdb) dir()
['__annotations__', '__builtins__', '__cached__', '__doc__', '__file__', '__loader__', '__name__', '__package__', '__return__', '__spec__', 'bar']
```
When it hits the breakpoint, bar has been imported to foo. With `dir()`, we can inspect the attributes of foo. Not surprising that bar is there as an attribute of the foo module object. 

If we go one step further and inspect the properties of bar, you guess what you would find there.

```bash
(Pdb) dir(bar)
['__builtins__', '__cached__', '__doc__', '__file__', '__loader__', '__name__', '__package__', '__spec__', 'hello_world']
```
This is why you can call the hello_world method in bar with `bar.hello_world`.

## What's different between `import` and `from  import `?
There are two significant differences:<br>

**1. Whether relative import is allowed**<br>
With `import` you must always use the FQN. On the other hand, you can perform **relative import** with `from import`. 

Suppose now your project has the following structure:

```bash
.
└── src
    ├── bar.py
    ├── dummy_submodule
    │   ├── dummy1.py
    │   └── dummy2.py
    └── foo.py
```

Within the dummy_submodule, dummy1 uses functions in dummy2, and thus you need to import dummy2 from dummy1. So intuitively, you tried to accomplish it with: 

```python
# dummy1.py
import dummy2 
```
And here again, the infamous `ModuleNotFoundError: No module named 'dummy2". 

The reason is that with `import`, it's assumed that you're providing an FQN, and each module along the path must be present in that name. For example, if the name is `foo.bar`, then from the perspective of the script from where the python interpreter got invoked, there must exist a module named *foo*, and within that module, there must be a bar. And in our case, *foo* can only see module *bar* and *dummy_submodule*, so it complaints. Therefore, this can be solved with `import dummy_submodule.dummy2`.

However, it may be too verbose to use the fully qualified name when you have a rather complex nested structure. And here `from import` comes to the rescue. 

```python
# dummy1.py
from . import dummy2

# A trick here is with every dot more, it goes up the structure by one level
#, i.e., you could do from ... import dummy2 if you have a structure like 

# .
# └── src
#     ├── bar.py
#     ├── dummy_submodule
#     │   ├── dummy2.py
#     │   └── level1
#     │       └── level2
#     │           └── dummy1.py
#     └── foo.py
```
The relative import has the same effect as using the FQN and could be helpful when handling intra-package import. But do note that although it's an acceptable alternative to FQN, you should avoid using it as much as possible as it reduces the readability. (the newest [PEP8](https://www.python.org/dev/peps/pep-0008/#imports) no longer consider it a bad practice but still not preferable)

**2. What get exposed to the current module's global scope**<br>
With `import`, it's always a module-level import, which means only the module name is exposed to the current module's scope. To access the functions or classes, you need to use dot syntax. 

This can be verified by inspect the global scope of the module foo. As expected module bar is loaded into the global scope of foo.
```bash
-> breakpoint()
(Pdb) globals()
{'__name__': '__main__', '__doc__': None, '__package__': None, '__loader__': <_frozen_importlib_external.SourceFileLoader object at 0x1017e9ca0>, '__spec__': None, '__annotations__': {}, '__builtins__': <module 'builtins' (built-in)>, '__file__': '/Users/chegnruizhao/Repos/private/python_import/src/foo.py', '__cached__': None, 'bar': <module 'bar' from '/Users/chegnruizhao/Repos/private/python_import/src/bar.py'>, '__return__': None}
```

But with `from import` you can do something like

```Python
from dummy2 import hello_world
```

When we inspect the global scope again, module bar is no longer there. Instead, hello_world is directly loaded into the global scope. And you can invoke the function directly with `hello_world()`
```bash
(Pdb) globals()
{'__name__': '__main__', '__doc__': None, '__package__': None, '__loader__': <_frozen_importlib_external.SourceFileLoader object at 0x1087ccca0>, '__spec__': None, '__annotations__': {}, '__builtins__': <module 'builtins' (built-in)>, '__file__': '/Users/chegnruizhao/Repos/private/python_import/src/foo.py', '__cached__': None, 'hello_world': <function hello_world at 0x1088b4670>, '__return__': None}
```

However, what will happen when there's another module imported in the same way and also contains a `hello_world` function? This time there's another module called dummy. Dummy and bar both implement an awsome hello_world function:

```python
def hello_world():
    print(f"hello from {__name__}")
```

Within foo, we import both dummy and bar with the `from` syntax:

```python
from bar import hello_world
from dummy import hello_world

hello_world()
```

When we run foo.py, here is the output:

```bash
python3 src/foo.py
hello from dummy
```
So dummy wins! This reveals the issue with `from` style import, it pollutes the namespace of the current module! So do keep this in mind and use it with caution.





## What happened during importing?
Have you ever wondered what happened during importing? Is it like C `include`, which is pure text substitution or something else? The story starts from `finder` and `loader`, which are two objects that Python uses to find and load the modules. Of course, there's way more than that; for details, please head to [python doc: the import system](https://docs.python.org/3/reference/import.html). 

Here I provide the TL;DR version. After the target module is found, the loader will execute the module's body with the `exec_module()` method. If everything goes well, the module will be cached in `sys.modules` and thus avoid reloading the module multiple times when it gets imported again. 

The takeaway here is that all the code in the module's body is executed exactly once when it's imported. You can alter that with `importlib`, but that's out of the scope of this article. 

## How does Python find the module to be imported?
In *What happened during importing*, we discussed that when a module is imported, Python will first search the `sys.modules` for the cached module. If this is not the first time importing this module, it would likely be found in the cache(unless you intentionally remove it from sys.modules). When the module couldn't be found in sys.modules, the meta path finder will determine whether they can locate the module. You can customize the import system's behavior by replacing the `sys.meta_path`, which is out of the scope of this article. If you're interested in implementing your import system, take a look at [python doc: the import system](https://docs.python.org/3/reference/import.html).

Like superheroes, the default finders have different capabilities, including locating built-in modules, [frozen modules](https://wiki.python.org/moin/Freeze) and modules on `import path`. The first two are straightforward. What we care about as a newbie is the last one. So what is this `import path`? To make my life easier, I tend to equate it with `sys.path`, which consists of: 

1. the directory containing the script that was used to invoke the Python interpreter
2. paths in environment variable PYTHONPATH
3. installation-dependent default paths(site-package paths, etc)
   

You can inspect the sys.path by printing it out like any other plain list. Notice that the first path in my output from Python REPL is an empty string. This is because I'm invoking the interpreter in python REPL.
```bash
>>> sys.path
['', '/usr/local/Cellar/python@3.9/3.9.9/Frameworks/Python.framework/Versions/3.9/lib/python39.zip', '/usr/local/Cellar/python@3.9/3.9.9/Frameworks/Python.framework/Versions/3.9/lib/python3.9', '/usr/local/Cellar/python@3.9/3.9.9/Frameworks/Python.framework/Versions/3.9/lib/python3.9/lib-dynload', '/usr/local/lib/python3.9/site-packages', '/Users/chegnruizhao/Repos/prd/CETLZAdfSharedLayers/mailer-master']
```
Python will search these paths for the FQN of the module to be imported. You are free to modify the sys.path, which is simply a list of strings by `sys.path.append(path_to_your_module)`. Although tempting, this should not be used in production. 

## Conclusion
Don't make the structure of your project too complex. Use `setuptools` to manage the intra-project dependencies, and reduce the usage of relative import and manipulation of sys.path. Hopefully, you will never have to meet ModuleNotFoundError again(highly unlikely ;) )


## References
1. **The import system**: https://docs.python.org/3/reference/import.html
2. **Freeze**: https://wiki.python.org/moin/Freeze
3. **Importing from a relative path in Python**: https://stackoverflow.com/questions/7505988/importing-from-a-relative-path-in-python