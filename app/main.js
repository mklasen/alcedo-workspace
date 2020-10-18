const {
  app,
  BrowserWindow
} = require('electron')
const exec = require('child_process').exec;
const ipc = require('electron').ipcMain;
const spawn = require('child_process').spawn;
const fs = require('fs');
var path = require('path');


function createWindow() {
  const win = new BrowserWindow({
    width: 1400,
    height: 768,
    webPreferences: {
      nodeIntegration: true
    }
  })

  win.loadFile('index.html')
  win.webContents.openDevTools()

  const cwd = path.dirname(process.cwd());

  // Initialise
  init(win, cwd);


  // Receiving a request from frontend
  ipc.on('main-action', (event, data) => {

    let config = {
      'cwd': cwd,
      'command': [],
      'isActive': '',
    };

    if (data.type === 'site') {
      config.cwd += '/sites/' + data.name;
    }

    config.command.push('docker-compose');

    // Check if the server is up.

    // Get all services
    exec('docker-compose ps --services', {
      cwd: config.cwd
    }).stdout.on('data', (data) => {
      services = data.split(/\n/);
      
      // Get running services
      exec('docker-compose ps --services --filter "status=running"', {
        cwd: config.cwd
      }).stdout.on('data', (runningServices) => {

        services.map((service) => {
          if (service !== '') {
            // If one of the services is not running, mark running as false
            if (runningServices.search(service) === -1) {
              data.isActive = false;
            }
          }
        });

      });
    });


    config.command.push(data.action);

    let executeCommand = config.command.join(' ');

    win.webContents.send("output", '<span class="block text-green-400 font-medium text-xl">Executing ' + executeCommand + ' in ' + config.cwd + '</span>');

    exec(executeCommand, {
      cwd: config.cwd
    }).stdout.on('data', (data) => {
      win.webContents.send("output", '<span class="block text-xs">' + data.toString() + '</span>');
    });
  });

}

app.whenReady().then(createWindow)

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow()
  }
})

function init(win, path) {

  let getServices = exec('docker-compose ps --services', {
    cwd: path
  });

  getServices.stdout.on('data', (data) => {
    services = data.split(/\n/);

    let getRunningServices = exec('docker-compose ps --services --filter "status=running"', {
      cwd: path
    });
    getRunningServices.stdout.on('data', (runningServices) => {

      let isActive = true;

      services.map((service) => {
        if (service !== '') {
          // If one of the services is down
          console.log(runningServices.search(service));
          if (runningServices.search(service) === -1) {
            isActive = false;
          }
        }
      });

      let config = {
        'name': 'main-server',
        'title': 'Start & stop servers',
        'description': 'Hitting this button will start or stop your docker-compose proxy server.',
        'isActive': isActive,
        'type': 'server'
      };

      win.webContents.send("add-config", config);

      // Now check other sites
      fs.readdirSync(path + '/sites').forEach(file => {

        let projectPath = path + '/sites/' + file;
        console.log(projectPath);

        let envs = require('dotenv').config({ path: projectPath + '/.env' })
        
        let domains = envs.parsed.DOMAINS.split(',');

        let description = "Running on ";

        domains.map((domain) => {
          description += "<a class='text-purple-600' data-type='external-link' href='https://" + domain.toLowerCase() + "'>https://" + domain.toLowerCase() + "</a> ";
        })

        let config = {
          'name': file,
          'title': file,
          'isActive': true,
          'description': description,
          'type': 'site'
        }
        exec('docker-compose ps --services', {
          cwd: projectPath
        }).stdout.on('data', (projectServices) => {
          services = projectServices.split(/\n/);
          let getRunningServices = exec('docker-compose ps --services --filter "status=running"', {
            cwd: projectPath
          });
          getRunningServices.stdout.on('data', (runningServices) => {
            services.map((service) => {
              if (service !== '') {
                // If one of the services is down
                if (runningServices.search(service) === -1) {
                  config.isActive = false;
                }
              }
            });

            // Send to DOM
            win.webContents.send("add-config", config);
          });
        });
      });

    });
  });
}

// try {
//   require('electron-reloader')(module)
// } catch (_) {}