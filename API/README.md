# Troovy API #

## Prerequisites ##
- Ubuntu 14.04 or 16.04
- node.js `6.10.0`
- gmail account or other smtp account
- mongodb 
- Kurento Media Server
- Ffmpeg >= 3.3.3
- pm2

## Deployment

- Copy all `index.js.dist` files to `index.js` in **config** folder, change it for your needs and run

- Install dependencies of API
```
npm install
```
- Go to `public/javascripts` and install dependencies for workshops webpages
```
cd public/javascripts && npm install
```
- Build js-bundle for workshops webpages
```
npm run build
```

- Run Node.JS server
```
pm2 start app.js
```
- Setup Apache Virtual Host. Example of the configuration:
```
<VirtualHost *:443>
    ServerName troovy.com # only for example

    SSLEngine on
    SSLCertificateFile /etc/ssl/cert.pem
    SSLCertificateKeyFile /etc/ssl/private/privkey.pem
    SSLCertificateChainFile /etc/ssl/chain.pem

    RewriteEngine On
    RewriteCond %{REQUEST_URI}  ^/socket.io            [NC]
    RewriteCond %{QUERY_STRING} transport=websocket    [NC]
    RewriteRule /(.*)           ws://troovy.com:15030/$1 [P,L] # port of API Node.JS server

    ProxyPassMatch "^(\/admin)(.*)$" http://troovy.com:15034/$2 # port of Admin Panel Node.JS server 

    ProxyPass /  http://troovy.com:15030/ # port of API Node.JS server
    ProxyPassReverse / http://troovy.com:15030/ # port of API Node.JS server
</VirtualHost>

```