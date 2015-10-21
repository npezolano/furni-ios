#import "SnapshotHelper.js"

var target = UIATarget.localTarget();
var app = target.frontMostApp();
var window = app.mainWindow();

target.delay(3);
captureLocalizedScreenshot("0-Store");

target.frontMostApp().mainWindow().tableViews()[0].cells()[0].tap();
target.delay(5);
captureLocalizedScreenshot("1-Collection");

