@ECHO OFF
start cmd.exe /K "cd C:\Users\user\Documents\GitHub\kastoria-interactive && node broadcast.js"
start cmd.exe /K "cd C:\Users\user\Documents\GitHub\kastoria-interactive && git pull && gulp build && npm start"