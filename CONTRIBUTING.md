# CONTRIBUTING GUIDELINES

## Summary
- [Commits](#commits)
- [Working on tasks](#working-on-tasks)
- [Style guidelines](#style-guidelines)

***

## Commits
1. Write your commits in English.
2. You're allowed to make funny commits. `yeet`
3. Still try to make them clear.

## Working on tasks
1. Use `Yarn`, not `NPM`.
2. Your source-code should be in a subfolder of `src`.
3. Achieve your tasks on a separate branch. When you're done, make a pull request.
4. Always accompany your code with Jest tests.


## Style guidelines

1. Write your function and variable names in `camelCase`.
2. Write your class names in `PascalCase` *(that is, if you ever write classes <_<)*.
3. Write global constants in `UPPER_SNAKE_CASE`.

No other style guidelines for now. 好きにしようぜ！

If you want, there is a `.prettierrc` file for you to use to format your code.
The command you have to type goes as follows:
```bash
yarn prettier --write "src/$subfolder/**/*.$ext" "tests/$subfolder/**/*.test.$ext"
```
Where `$subfolder` is the subfolder you added your code in, and `$ext` is the extension of the files your code is into. For example, if you wrote your program in javascript, it will be `js`. If it was in typescript, it will be `ts`. If it was in coffeescript, it will be `coffee`.
