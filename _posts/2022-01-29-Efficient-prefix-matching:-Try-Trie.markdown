---
layout: post
tags: ["DataStructure", "Tutorial"]
title:  "Efficient prefix matching: Try Trie"
date:   2022-01-29 19:57:37 +0100
categories: DataStructure
---
While I was learning the source code of the [boto3 library](https://github.com/boto/boto3), a class caught my attention. The class is named `_PrefixTrie` which is used by `HierarchicaEmitter` for storing and searching for event handlers. The detail of `HierarchicaEmitter` is irrelevant to today's topic, however, this is the first time ever I have seen a `Trie`(pronounced 'try') in real life. I learned about this data structure in university and felt never really understand it thoroughly. So I decide to have a closer look at it.

## Introduction

### Use Case
In `HierarchicaEmitter` class of boto3, the event handlers have a hierarchical structure and can be denoted by name like `foo.bar.hello.world...`. By searching for a handler named `foo.bar.buz` a list of handlers will be returned `[foo.bar.buz, foo.bar, foo]`.

### Definition of a Trie
A trie is a tree-based data structure for storing strings in order to support for fast pattern matching[1]. For a tree T to become a standard Trie, it has to satisfy three conditions:
* Each node of T besides the root node, must be labeled by a character
* Each node of T must have distinct children
* Concatenate the labels from root to the leafs of T, forms a distinct string associated with the path. 

So basically, Trie is a special tree of which each path represents a distinct word which provides good performance in word matching or prefix searching.  

### Time complexity of basic operations
Depending on the implementation, the complexity slightly varies. However, under big O notation it should be the same. So all the complexity are default in big O notation.
* **Insert value**: N where N is the length of the input str.
* **Search for existence of an item**: N where N is the length of the input str.
* **Search for words that have common prefix**: M where M is the number of nodes in the Trie. Under the worst case scenario e.g, use '' as prefix to search, it will traverse the whole Trie to collect all possible words.
* **Remove item**: N where N is the length of the input str. 

Though you may achieve O(1) performance in word matching with a hash map. However, in prefix searching, a normal implementation with a list of strings require O(MN) time where M is the strings in the list and N is the length of the prefix and it could be quite big when the the amount of strings to be searched is big. Overall, Trie provides a balanced performance in these scenarios.

### Space complexity
The space complexity of a standard Trie is O(M) where M is the the total length of input strings. It can be further optimized with a compressed Trie of which a leaf node may store multiple characters instead of only one. 

## Implementation
I implemented the most basic Trie in Python for the purpose of gaining better understanding of this data structure. Note that the code is not strictly tested and in no way the most efficient or robust implementation. 

Some ideas I have to extend the Trie including: support wildcard, walk function which will return all strings in a hierarchical way, search function that returns all strings which are included by the target string.

```python
from typing import List

class MyStandardTrie:
    def __init__(self):
        self._root = {'children': {}, 'end_of_word': None}
        
    def append_item(self, item:str)->None:
        current = self._root
        for c in item:
            if c in current['children']:
                current = current['children'][c]
            else:
                current['children'][c] = {'children': {}, 'end_of_word': False}
                current = current['children'][c]
        current['end_of_word'] = True
        
    def search_item(self, item:str)->bool:
        current = self._root
        for c in item:
            if c in current['children']:
                current = current['children'][c]
            else:
                return False
        if current['end_of_word']:
            return True
        return False
    
    def _dfs_search_prefix(self, children:dict)->List[str]:
        stack = []
        stack.append(None)
        stack += children.items()
        word = ''
        words = []
        while len(stack) > 0:
            node = stack.pop()
            if node is None:
                word = word[0:-1]
                continue
            word += node[0]
            if node[1]['end_of_word']:
                words.append(word)
            stack.append(None)
            stack += node[1]['children'].items()
        return words
                
            
    
    def search_prefix(self, prefix: str)->List[str]:
        current = self._root
        res = []
        for c in prefix:
            if c in current['children']:
                current = current['children'][c]
            else:
                return res
        distinct_parts = self._dfs_search_prefix(current['children'])
        res = list(map(lambda x: prefix + x, distinct_parts))
        if current['end_of_word']:
            res.append(prefix)
        return res
    
    def _recursive_remove_item(self, idx: int, item:str, current:dict) -> bool:
        c = item[idx]
        if idx == len(item) - 1:
            if len(current['children'][c]['children']) == 0:
                del current['children'][c]
                return True
            else:
                current['children'][c]['end_of_word'] = False
                return False
        if c in current['children'] and self._recursive_remove_item(idx + 1, item, current['children'][c]):
            if len(current['children'][c]['children']) == 0 and not current['children'][c]['end_of_word']:
                del current['children'][c]
                return True
        return False
    
    def remove_item(self, item: str)->None:
        self._recursive_remove_item(0, item, self._root)
        
    def __str__(self):
        return str(self._root)

```

## Reference
[1] Drozdek, Adam. “Data Structures and Algorithms in Java, Second Edition.” (2004).