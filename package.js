Package.describe({
  summary: "Control mergebox of publish endpoints",
  version: '0.3.0',
  name: 'peerlibrary:control-mergebox',
  git: 'https://github.com/peerlibrary/meteor-control-mergebox.git'
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@1.3.4.4');

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
    'peerlibrary:fiber-utils@0.6.0',
    'peerlibrary:extend-publish@0.4.0'
  ], 'server');

  api.addFiles([
    'livedata_server.js',
    'server.coffee'
  ], 'server');

  api.addFiles([
    'client.coffee'
  ], 'client');
});

Package.onTest(function (api) {
  api.versionsFrom('METEOR@1.3.4.4');

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
    'peerlibrary:classy-test@0.2.26'
  ]);

  api.add_files([
    'tests.coffee'
  ]);
});
