c = get_config()
c.NotebookApp.certfile = u'/usr/share/ssl/stical.crt'
c.NotebookApp.keyfile = u'/usr/share/ssl/stical.key'
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.open_browser = False
c.NotebookApp.password = '<hash>'