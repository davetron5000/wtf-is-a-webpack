This is chapter 2.

* it has
* a bullet list
* ya know?

!EDIT_FILE index.html <!-- -->
{
  "match": "    <title>",
  "insert_after": [
    "    <script>",
    "      console.log('Hi!');",
    "    </script>"
  ]
}
!END EDIT_FILE

And now:

!DO_AND_DUMP_CONSOLE index.html
console.log("Dynamic!");
!END DO_AND_DUMP_CONSOLE

That's it!
