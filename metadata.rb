maintainer       "hopsor"
maintainer_email "hopsor@gmail.com"
license          "MIT"
description      "Configure and deploy shoryuken on opsworks."

name   'opsworks_shoryuken'
recipe 'opsworks_shoryuken::setup',     'Set up shoryuken worker.'
recipe 'opsworks_shoryuken::configure', 'Configure shoryuken worker.'
recipe 'opsworks_shoryuken::deploy',    'Deploy shoryuken worker.'
recipe 'opsworks_shoryuken::undeploy',  'Undeploy shoryuken worker.'
recipe 'opsworks_shoryuken::stop',      'Stop shoryuken worker.'
