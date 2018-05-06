# Future

Just a list of syntax/implementation details or possible solutions.  These haven't yet been implemented but its a way for me to show my ideas and store them in the same place.  To simulate a function i'll use the `x => ...` syntax that is known from C#.  Also I'll remove any extraneous 'types' that currently need to be retrieved as we can't have `var` return functions (and by making the variable fully `var` it gets messy when we want to make it clear it should be a function).

## Ordering

```C#
while (Lazy.init(obj).orderByAscending(x => x.FirstName, buf).thenByDescending(x => x.LastName, buf)) |next| {
    ...
}

// Or
while (Lazy.init(obj)
           .order((a, b) => Lazy.LessThanOr(a.FirstName, b.FirstName,
                  () => a.LastName > b.LastName))) |next| {
    ...
}
```

I'm currently settling on the first.