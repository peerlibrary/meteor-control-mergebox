Package.describe({
  summary: "Disable mergebox for publish endpoints",
  version: '0.1.2',
  name: 'peerlibrary:disable-mergebox',
  git: 'https://github.com/peerlibrary/meteor-disable-mergebox.git'
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@1.0.3.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'underscore',
    'mongo',
    'ddp-server',
    'ejson'
  ], 'server');

  api.addFiles([
    'livedata_server.js',
    'server.coffee'
  ], 'server');
});

Package.onTest(function (api) {
  // Core dependencies.
  api.use([
    'coffeescript',
    'underscore'
  ]);

  // Internal dependencies.
  api.use([
    'peerlibrary:disable-mergebox'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:classy-test@0.2.19'
  ]);

  api.add_files([
    'tests.coffee'
  ]);
});
