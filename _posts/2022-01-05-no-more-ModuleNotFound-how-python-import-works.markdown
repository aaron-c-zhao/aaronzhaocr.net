---
layout: post
tags: ["Python", "Tutorial"]
title:  "No more ModuleNotFound: how Python import works"
date:   2022-01-05 20:37:56 +0100
categories: Python
---
Newcomers to the Python world like me inevitably gonna encouter this error `ModuleNotFound`. After realizing that it won't go anywhere messing around while hoping it magically fixex itself. I try to take a peek under the hood and find answer for some of my questions. 

## What are you importing with `import`?
In Python, everything is an object. So with `import`, ultimately you are importing an module object which will be put into the global scope of your current module as an attribute. Within the imported module object, sit the class and function objects which you can access with the *dot* syntax e.g. `foo.bar.hello_world` . And this odd name with dots is actullay something called the [fully qualified name](https://docs.python.org/3/glossary.html#term-qualified-name)(FQN) of the functions or classes. In this way, the other module severs as an individual 'namespace' and prevents name conclision between modules. 

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

With the break point set in foo we can interact and inspect the stack content of the program.

```bash
-> breakpoint()
(Pdb) dir()
['__annotations__', '__builtins__', '__cached__', '__doc__', '__file__', '__loader__', '__name__', '__package__', '__return__', '__spec__', 'bar']
```
When it hits the breakpoint, bar has been imported to foo. With `dir()` we can inspect the attributes of foo. Not suprising that bar is there as an attribute of the foo module object. 

If we go one step further and inspect the properties of bar, you guess what you would find there.

```bash
(Pdb) dir(bar)
['__builtins__', '__cached__', '__doc__', '__file__', '__loader__', '__name__', '__package__', '__spec__', 'hello_world']
```
So this is the truth of what you're importing and why you can access the functions with dots after import. 

## What's the different between `import` and `from  import `?
There are two major differences:<br>

**1. Whether relative import is allowed**<br>
With `import` you must always use the FQN. On the other hand, with `from import` you can perform **relative import**. 

Suppose now your peoject has the following struture:
```bash
.
└── src
    ├── bar.py
    ├── dummy_submodule
    │   ├── dummy1.py
    │   └── dummy2.py
    └── foo.py
```

Within the dummy_submodule dummy1 utilizes functions in dummy2, and thus you need to import dummy2 from dummy1. So intuitively you tried to accomplish it with: 

```python
# dummy1.py
import dummy2 
```
And here again, the infamous `ModuleNotFoundError: No module named 'dummy2'`. 

The reason is that with `import`, it's assumed that you're providing a FQN, and each module along the path must be present in that name. For example, if the name is `foo.bar` then from the perspective of the `__main__` module(the script that is being executed) there must exists a module named *foo* and within that module there must be a bar. And in our case, *foo* can only see module *bar* and *dummy_submodule*, so it compliants. Therefore, this can be solvd with `import dummy_submodule.dummy2`.

However, when you have a rather complex nested structure, it maybe too verbose to use the fully qualified name. And here `from import` comes to the rescue. 
```python
# dummy1.py
from . import dummy2

# A trick here is with every dot more, it goes up the structure by one level
# i.e. you could do from ... import dummy2 if you have a structure like 

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
This has the same effect as using the FQN. Though it's an acceptable alternative to FQN, you should avoid using it as much as possible as it reduce the readbility. (the newest [PEP8](https://www.python.org/dev/peps/pep-0008/#imports) no long consider it an bad pratice but still not preferable)

**2. Whther you can expose functions and classes directy instead of module**<br>
With `import` it's always a module level import which means only the module name is exposed to the scope of the current module. To access the functions or classes, you need to use dot syntax. But with `from import` you can do something like
```python
from dummy2 import hello_world
```
This attach the hello_world function directly to the current module and may save you some typing. But it comes with risk of pollute your namespace. So it should be used with caution. 

## What happens during importing?
Have you ever wondered what happens during importing? Is it like C `include` which is pure text substitution or something else. Well, the sotry starts from `finder` and `loader` which are two types of objects that python use to find and load the modules. Of course, there's way more than that, for details please head to [python doc: the import system](https://docs.python.org/3/reference/import.html). 

Here I provide the TL;DR version, which is after the target module is found, loader will execute the body of the module with `exec_module()` method. If everything goes well, the module will be cached in `sys.modules` and thus avoid reloading the module multiple times when it get imported angin. 

The take away here is that all the code in the body of the module is executed exactly once when it's imported. You can alter that with `importlib` but that's out of the scope of this article. 

## How Python find the module to be imported?

