module.exports = {
    apps: [
        {
            name: "troovy_admin_panel",
            script: "./server/index.js",
            watch: false,
            env_production: {
                "NODE_ENV": "production",
            }
        }
    ]
};
