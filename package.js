Package.describe({
  summary: "Control mergebox of publish endpoints",
  version: '0.1.3',
  name: 'peerlibrary:control-mergebox',
  git: 'https://github.com/peerlibrary/meteor-control-mergebox.git'
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@1.2.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'underscore',
    'mongo',
    'ddp',
    'ejson',
    'mongo-id'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:fiber-utils@0.6.0'
  ]);

  api.addFiles([
    'livedata_server.js',
    'server.coffee'
  ], 'server');

  api.addFiles([
    'client.coffee'
  ], 'client');
});

Package.onTest(function (api) {
  // Core dependencies.
  api.use([
    'coffeescript',
    'underscore',
    'mongo'
  ]);

  // Internal dependencies.
  api.use([
    'peerlibrary:control-mergebox'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:classy-test@0.2.23'
  ]);

  api.add_files([
    'tests.coffee'
  ]);
});
