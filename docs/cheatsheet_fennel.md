# Fennel Cheatsheet

## Basic Syntax

- **Commentary:** `;; This is a comment`
- **Variable assignment:** `(var t 0)` or `(global t 0)` or `(local t 0)`
- **Functions:** 
```fennel
(fn add [a b]
  (+ a b))
```
- **If condition:**
```fennel
(if (> a b)
  (print "a is greater")
  (print "b is greater"))
```
- **Tables (Arrays):** `[1 2 3]`
- **Tables (Key/Value):** `{ :key "value" }`
