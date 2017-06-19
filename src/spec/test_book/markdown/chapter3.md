Let's take a screenshot:

!SCREENSHOT "Some image" index.html image.png

Now, let's `ls`:

!SH ls -1

And who can forget `package.json`:

!CREATE_FILE package.json
{
}
!END CREATE_FILE

!PACKAGE_JSON
{
  "scripts": {
    "webpack": "$(yarn bin)/webpack"
  }
}
!END PACKAGE_JSON

One more change to `package.json`:

!PACKAGE_JSON
{
  "config": {
    "webpack_args": " --config webpack.config.js --display-error-details"
  }
}
!END PACKAGE_JSON

Let's much once more:


!DO_AND_SCREENSHOT "Updated image" index.html updated.png
console.log("Nothing to see here");
!END DO_AND_SCREENSHOT
