const electron = require('electron')
// Module to control application life.
const app = electron.app
// Module to create native browser window.
const BrowserWindow = electron.BrowserWindow

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is garbage collected.
let mainWindow

// var Kinect2 = require('kinect2'),
//     express = require('express'),
//     express_app = express(),
//     server = require('http').createServer(express_app),
//     io = require('socket.io').listen(server);

// var kinect = new Kinect2();

// if(kinect.open()) {
//     server.listen(8000);
//     console.log('Server listening on port 8000');
//     console.log('Point your browser to http://localhost:8000');
//     express_app.use(express.static('builds/development'));
//     express_app.get('/', function(req, res) {
//         res.sendFile(__dirname + '/builds/development/index.html');
//     });
//     kinect.on('bodyFrame', function(bodyFrame){
//         io.sockets.emit('bodyFrame', bodyFrame);
//     });

//     kinect.openBodyReader();
// }


function createWindow () {
  // Create the browser window.
  mainWindow = new BrowserWindow({width: 800, height: 600})
  mainWindow.setMenuBarVisibility(false)
  mainWindow.setKiosk(true)

  // and load the index.html of the app.
  mainWindow.loadURL(`file://${__dirname}/builds/development/index.html`)


  const id = electron.powerSaveBlocker.start('prevent-display-sleep');
  console.log(electron.powerSaveBlocker.isStarted(id));

  // Open the DevTools.
  //mainWindow.webContents.openDevTools()

  // Emitted when the window is closed.
  mainWindow.on('closed', function () {
    // Dereference the window object, usually you would store windows
    // in an array if your app supports multi windows, this is the time
    // when you should delete the corresponding element.
    mainWindow = null
    electron.powerSaveBlocker.stop(id);
  })
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.on('ready', createWindow)

// Quit when all windows are closed.
app.on('window-all-closed', function () {
  // On OS X it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

app.on('activate', function () {
  // On OS X it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (mainWindow === null) {
    createWindow()
  }
})

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.
