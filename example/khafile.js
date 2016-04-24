var project = new Project('Example');
project.addSources('Sources');
project.addSources('../Sources');
project.addAssets('Assets/**');

return project;