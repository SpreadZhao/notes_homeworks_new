# Vim Tutorial Summary

## Lesson 1

1. The cursor is moved using either the arrow keys or the `hjkl` keys.
2. To start Vim from the shell prompt type: `vim FILENAME <ENTER>`
3. To exit Vim type:
	1. `<ESC> :q! <ENTER>` to trash all changes;
	2. `<ESC> :wq <ENTER>` to save the changes;
4. To delete the character at the cursor type: `x`;
5. To insert or append text type:
	1. `i` type inserted text `<ESC>` insert before the cursor;
	2. `A` type appended text `<ESC>` append after the line;

> [!note]
> Pressing `<ESC>` will place you in Normal mode or will cancel an unwanted and partially completed command.

## Lesson 2

1. To delete from the cursor up to the next word type: `dw`;
2. To delete from the cursor up to the end of the word : `de`;
3. To delete from the cursor to the end of a line type: `d$`;
4. To delete a whole line type: `dd`
5. To repeat a motion prepend it with a number: `2w`
6. The format for a change command id:
	* `operator [number] motion`
	* where:
		* `operator`: is what to do, such as `d` for delete;
		* `[number]`: is an optional count to repeat the motion;
		* `motion`: moves over the text to operate on, such as `w`(word), `e`(end of word), `$`(end of the line), etc.
	* example:
		* `d3w`: delete from the cursor up to the next **three** words;
		* `d4e`: delete from the cursor up to the end of the next **four** words;
		* `d2d`: delete two lines;
		* also, `3dw`, `4de`, `2dd` also works.
7. To move to the start of the line use a zero: `0`;
8. To undo previdous actions, type: `u`(lowercase);
9. To undo all the changes on a line, type `U`(capital);
10. To undo the undo's, type: `CTRL-R`.

```ad-note
`dw` delete the current word **with the space after it**; while `de` don't do that.

![[Study Log/resources/Peek 2024-02-09 15-04.gif]] ![[Study Log/resources/Peek 2024-02-09 15-042.gif]]
```

## Lesson 3

1. To put back text that has just been deleted, type `p`. This puts the deleted text AFTER the cursor (if a line was deleted it will go on the line below the cursor);
2. To replace the character under the cursor, type `r` and then the character you want to have there;
3. The change operator allows you to change from the cursor to where the motion takes you. eg. Type `ce` to change from the cursor to the end of the word, `c$` to change to the end of a line;
4. The format for change is:
	* `c [number] motion`

## Lesson 4

1. `CTRL-G`: displays your location in the file and the file status;
	* `G` moves to the end of the file;
	* `[number] G` moves to that line number;
	* `gg` moves to the first line.
2. 📔
	* Typing `/` followed by a phrase searches FORWARD for the phrase;
	* Typing `?` followed by a phrase searched BACKWARD for the phrase;
	* After a search type `n` to find the next occurrence in the same direction or `N` to search in the opposite direction;
	* `CTRL-O` takes you back to older positions, `CTRL-I` to newer positions;
3. Typing `%` while the cursor is on a `(`, `)`, `[`, `]`, `{`, or `}` goes to its match;
4. 📔
	* To substitute new for the first old in a line type `:s/old/new`;
	* To substitute new for all 'old's on a line type `:s/old/new/g`;
	* To substitute phrases between two line `#`'s type `#,#s/old/new/g`;
	* To substitute all occurrences in the line file type `:%s/old/new/g`;
	* To ask for confirmation each time add 'c' `:%s/old/new/gc`.

