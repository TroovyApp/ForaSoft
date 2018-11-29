# Troovy Admin Panel #

## Prerequisites ##
- node.js `6.10.0`
- pm2

## Deployment ##

- Change Troovy API address `.env.production`
- Change run configuration in `ecosystem.config.js`
- Change port of static server in `server/.env.production` *(Optional)*
- Install dependencies
```
npm install
```
- Build js-bundle
```
npm run build_prod
```
- Start Node.JS server
```
pm2 start ecosystem.config.js
```
- Setup Apache Virtual Host. You can find example in **../API/README.md**
- Open  **|server name from virtual host configuration|**/admin and ensure everything is working