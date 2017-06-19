This is chapter 1.

* it has
* a bullet list
* ya know?

!CREATE_FILE index.html
<!DOCTYPE html>
<html>
  <head>
    <title>This is a test</title>
    <script>
      console.log("Hello world!");
    </script>
  </head>
  <body>
    <h1>This is a test</h1>
    <p>
      This is some code
    </p>
  </body>
</html>
!END CREATE_FILE

And now:

!DUMP_CONSOLE index.html

That's it!
